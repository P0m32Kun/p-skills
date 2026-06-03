#!/usr/bin/env node
/**
 * Learning Observer — PostToolUse hook
 *
 * 采集工具使用和 skill 执行信号，写入 observations.jsonl。
 * 基于 SkillOpt 的观察层设计，适配 P-Skills 开发流程场景。
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const crypto = require('crypto');

// ── 配置 ─────────────────────────────────────────────────────────────────────

const OBSERVED_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'Bash']);
const SKILL_TRIGGERS = {
  'fix-bug': ['修复bug', 'fix bug', 'hotfix', '故障排查', 'debug'],
  'develop-feature': ['新需求', 'develop feature', '开发功能', '实现功能'],
  'brainstorming': ['设计讨论', 'brainstorm', '方案探索', '需求澄清'],
  'writing-plans': ['实施计划', 'writing plans', '拆解任务', 'plan'],
  'tdd': ['TDD', '测试驱动', '红绿重构'],
  'doc-sync': ['文档同步', 'doc sync', '更新文档'],
  'deploy': ['发布', 'deploy', '部署', 'Docker'],
  'retrospective': ['回顾', 'retrospective', '复盘'],
};

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

function extractFilePath(input) {
  const toolInput = input.input || input.tool_input || {};
  return toolInput.file_path || toolInput.path || toolInput.filePath || '';
}

function detectTriggeredSkill(input) {
  // 从 user message 或 tool input 中检测触发的 skill
  const userMsg = (input.user_message || '').toLowerCase();
  const toolInput = input.input || input.tool_input || {};

  for (const [skill, triggers] of Object.entries(SKILL_TRIGGERS)) {
    for (const trigger of triggers) {
      if (userMsg.includes(trigger.toLowerCase())) {
        return skill;
      }
    }
  }

  // 检查是否在编辑 skill 文件
  const filePath = extractFilePath(input);
  if (filePath.includes('/skills/') && filePath.endsWith('SKILL.md')) {
    const match = filePath.match(/skills\/([^/]+)\//);
    if (match) return `editing:${match[1]}`;
  }

  return null;
}

function getLearningDir(projectId) {
  return path.join(
    process.env.HOME || require('os').homedir(),
    '.p-skills',
    'learning',
    'projects',
    projectId
  );
}

function ensureDir(dir) {
  try {
    fs.mkdirSync(dir, { recursive: true });
  } catch {}
}

function appendJsonl(filePath, data) {
  try {
    ensureDir(path.dirname(filePath));
    fs.appendFileSync(filePath, JSON.stringify(data) + '\n', 'utf8');
  } catch (err) {
    // 静默失败，但记录到 stderr 以便调试
    if (process.env.P_SKILLS_DEBUG) {
      process.stderr.write(`[learning-observer] Error: ${err.message}\n`);
    }
  }
}

// ── 主逻辑 ─────────────────────────────────────────────────────────────────────

function main() {
  // 检查是否禁用
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

  // 只观察特定工具
  if (!OBSERVED_TOOLS.has(toolName)) {
    process.exit(0);
  }

  const projectDir = input.cwd || process.cwd();
  const projectId = getProjectId(projectDir);
  const sessionId = input.session_id || 'unknown';
  const filePath = extractFilePath(input);
  const fileExt = filePath ? path.extname(filePath) : '';

  // 构建观察记录
  const observation = {
    timestamp: new Date().toISOString(),
    session_id: sessionId,
    tool: toolName,
    file_path: filePath,
    file_ext: fileExt,
    project_id: projectId,

    // Skill 执行信号
    skill_triggered: detectTriggeredSkill(input),

    // 用户行为信号（默认值，由 session-tracker 更新）
    user_reverted: false,
    user_manually_edited: false,

    // 执行指标
    tool_input_size: JSON.stringify(input.input || input.tool_input || {}).length,
  };

  // 写入观察数据
  const learningDir = getLearningDir(projectId);
  const observationsFile = path.join(learningDir, 'observations.jsonl');
  appendJsonl(observationsFile, observation);

  // 更新 session 统计
  const sessionFile = path.join(learningDir, 'sessions', `${sessionId}.json`);
  updateSessionStats(sessionFile, toolName, observation);
}

function updateSessionStats(sessionFile, toolName, observation) {
  ensureDir(path.dirname(sessionFile));

  let stats;
  try {
    stats = JSON.parse(fs.readFileSync(sessionFile, 'utf8'));
  } catch {
    stats = {
      session_id: observation.session_id,
      started_at: observation.timestamp,
      tool_calls: {},
      skill_triggers: [],
      total_calls: 0,
    };
  }

  // 更新工具调用计数
  stats.tool_calls[toolName] = (stats.tool_calls[toolName] || 0) + 1;
  stats.total_calls++;

  // 记录 skill 触发
  if (observation.skill_triggered) {
    if (!stats.skill_triggers.includes(observation.skill_triggered)) {
      stats.skill_triggers.push(observation.skill_triggered);
    }
  }

  stats.last_updated = observation.timestamp;

  try {
    fs.writeFileSync(sessionFile, JSON.stringify(stats, null, 2), 'utf8');
  } catch {}
}

main();
