#!/usr/bin/env node
/**
 * Session Tracker — PostToolUse + Stop hook
 *
 * 追踪整个 session 的 skill 执行情况，计算 session 级别的指标。
 * 当 session 结束时，触发训练循环检查。
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const crypto = require('crypto');

// ── 配置 ─────────────────────────────────────────────────────────────────────

const TRAINING_INTERVAL = 5; // 每 5 个 session 触发一次训练
const LEARNING_DIR = path.join(
  process.env.HOME || require('os').homedir(),
  '.p-skills',
  'learning'
);

// ── 工具函数 ───────────────────────────────────────────────────────────────────

function getProjectId(projectDir) {
  try {
    const remoteUrl = execSync('git remote get-url origin', {
      cwd: projectDir,
      encoding: 'utf8',
      timeout: 5000,
      stdio: ['pipe', 'pipe', 'pipe'],
    }).trim();
    return crypto
      .createHash('md5')
      .update(remoteUrl.replace(/\.git$/, ''))
      .digest('hex')
      .substring(0, 12);
  } catch {
    return crypto
      .createHash('md5')
      .update(path.basename(projectDir))
      .digest('hex')
      .substring(0, 12);
  }
}

function ensureDir(dir) {
  try {
    fs.mkdirSync(dir, { recursive: true });
  } catch {}
}

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
}

function writeJson(filePath, data) {
  try {
    ensureDir(path.dirname(filePath));
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
  } catch {}
}

function appendJsonl(filePath, data) {
  try {
    ensureDir(path.dirname(filePath));
    fs.appendFileSync(filePath, JSON.stringify(data) + '\n', 'utf8');
  } catch {}
}

// ── Session 指标计算 ──────────────────────────────────────────────────────────

function calculateSessionScore(sessionStats) {
  const {
    tool_calls = {},
    skill_triggers = [],
    total_calls = 0,
    user_reverts = 0,
    user_manual_edits = 0,
    stages_completed = [],
  } = sessionStats;

  // 流程完成率：如果触发了 skill，检查是否完成了关键阶段
  let completion_rate = 1.0; // 默认完成
  if (skill_triggers.length > 0) {
    const expectedStages = ['Research', 'Design', 'Implement', 'Verify'];
    const completedExpected = stages_completed.filter(s =>
      expectedStages.some(e => s.toLowerCase().includes(e.toLowerCase()))
    );
    completion_rate = completedExpected.length / expectedStages.length;
  }

  // 建议采纳率：基于回滚次数
  const revert_rate = total_calls > 0 ? user_reverts / total_calls : 0;
  const adoption_rate = 1 - revert_rate;

  // 效率得分：工具调用次数的倒数归一化
  // 假设理想的工具调用次数是 20-50 次
  const efficiency_score = 1 / (1 + Math.max(0, total_calls - 50) / 50);

  // 综合分数
  const composite =
    0.4 * completion_rate +
    0.3 * adoption_rate +
    0.3 * efficiency_score;

  return {
    completion_rate,
    adoption_rate,
    efficiency_score,
    composite,
    details: {
      total_calls,
      user_reverts,
      user_manual_edits,
      skill_triggers,
      stages_completed,
    },
  };
}

// ── 训练触发 ──────────────────────────────────────────────────────────────────

function maybeTriggerTraining(projectId) {
  const stateFile = path.join(
    LEARNING_DIR,
    'projects',
    projectId,
    'training_state.json'
  );

  let state = readJson(stateFile) || {
    project_id: projectId,
    session_count: 0,
    last_training: null,
    epoch: 0,
  };

  state.session_count++;

  // 检查是否需要触发训练
  if (state.session_count % TRAINING_INTERVAL === 0) {
    state.epoch++;
    state.last_training = new Date().toISOString();
    writeJson(stateFile, state);

    // 异步触发训练循环
    triggerEvolution(projectId, state.epoch);
    return true;
  }

  writeJson(stateFile, state);
  return false;
}

function triggerEvolution(projectId, epoch) {
  const evolveScript = path.join(__dirname, 'evolution-train.js');

  // 检查训练脚本是否存在
  if (!fs.existsSync(evolveScript)) {
    if (process.env.P_SKILLS_DEBUG) {
      process.stderr.write(
        `[session-tracker] Evolution script not found: ${evolveScript}\n`
      );
    }
    return;
  }

  try {
    const { fork } = require('child_process');
    const child = fork(evolveScript, ['--project', projectId, '--epoch', epoch.toString()], {
      detached: true,
      stdio: 'ignore',
    });
    child.unref();

    if (process.env.P_SKILLS_DEBUG) {
      process.stderr.write(
        `[session-tracker] Triggered evolution for project ${projectId}, epoch ${epoch}\n`
      );
    }
  } catch (err) {
    if (process.env.P_SKILLS_DEBUG) {
      process.stderr.write(
        `[session-tracker] Failed to trigger evolution: ${err.message}\n`
      );
    }
  }
}

// ── 主逻辑 ─────────────────────────────────────────────────────────────────────

function main() {
  if (process.env.P_SKILLS_LEARNING === 'off') {
    process.exit(0);
  }

  let input;
  try {
    input = JSON.parse(fs.readFileSync('/dev/stdin', 'utf8'));
  } catch {
    process.exit(0);
  }

  const toolName = input.tool_name || input.name || '';
  const projectDir = input.cwd || process.cwd();
  const projectId = getProjectId(projectDir);
  const sessionId = input.session_id || 'unknown';

  const sessionFile = path.join(
    LEARNING_DIR,
    'projects',
    projectId,
    'sessions',
    `${sessionId}.json`
  );

  // 读取当前 session 统计
  let sessionStats = readJson(sessionFile) || {
    session_id: sessionId,
    started_at: new Date().toISOString(),
    tool_calls: {},
    skill_triggers: [],
    stages_completed: [],
    total_calls: 0,
    user_reverts: 0,
    user_manual_edits: 0,
  };

  // 更新统计
  sessionStats.tool_calls[toolName] = (sessionStats.tool_calls[toolName] || 0) + 1;
  sessionStats.total_calls++;
  sessionStats.last_updated = new Date().toISOString();

  // 检测用户回滚行为（通过 git 操作）
  if (toolName === 'Bash') {
    const command = (input.input || input.tool_input || {}).command || '';
    if (command.includes('git checkout') && command.includes('--')) {
      sessionStats.user_reverts++;
    }
    if (command.includes('git revert')) {
      sessionStats.user_reverts++;
    }
  }

  // 检测 skill 阶段完成（通过文件编辑模式）
  if (['Edit', 'Write'].includes(toolName)) {
    const filePath = (input.input || input.tool_input || {}).file_path || '';
    if (filePath.includes('SKILL.md')) {
      sessionStats.stages_completed.push('skill-edit');
    }
  }

  writeJson(sessionFile, sessionStats);

  // 如果是 Stop 工具（session 结束），计算分数并检查是否触发训练
  if (toolName === 'Stop' || input.hook_type === 'Stop') {
    const score = calculateSessionScore(sessionStats);
    sessionStats.score = score;
    writeJson(sessionFile, sessionStats);

    // 记录到全局日志
    const logFile = path.join(
      LEARNING_DIR,
      'projects',
      projectId,
      'session_scores.jsonl'
    );
    appendJsonl(logFile, {
      session_id: sessionId,
      timestamp: new Date().toISOString(),
      score: score.composite,
      details: score.details,
    });

    // 检查是否触发训练
    maybeTriggerTraining(projectId);
  }
}

main();
