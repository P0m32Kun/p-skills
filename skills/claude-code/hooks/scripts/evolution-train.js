#!/usr/bin/env node
/**
 * Evolution Train — 自进化训练循环主控脚本
 *
 * 基于 SkillOpt 的 ReflACT 流水线，实现 P-Skills 的自进化训练循环。
 * 由 session-tracker 在每 N 个 session 后触发。
 *
 * 流程：
 * 1. 读取观察数据
 * 2. 反思（Reflect）：分析观察数据，识别模式
 * 3. 提议（Propose）：生成 skill 改进 patches
 * 4. 验证（Validate）：对比改进前后的效果
 * 5. 应用（Apply）：应用验证通过的改进
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ── 配置 ─────────────────────────────────────────────────────────────────────

const LEARNING_DIR = path.join(
  process.env.HOME || require('os').homedir(),
  '.p-skills',
  'learning'
);
const SKILLS_DIR = path.join(
  process.env.HOME || require('os').homedir(),
  '.p-skills',
  'skills'
);

// 学习率调度
const LR_CONFIG = {
  mode: 'cosine',        // constant | linear | cosine
  maxEdits: 4,
  minEdits: 1,
  totalEpochs: 20,
};

// 验证门禁
const GATE_CONFIG = {
  mode: 'hard',          // hard | soft
  improvementThreshold: 0.02,
};

// ── 工具函数 ───────────────────────────────────────────────────────────────────

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
}

function writeJson(filePath, data) {
  try {
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
  } catch {}
}

function readJsonl(filePath) {
  try {
    const data = fs.readFileSync(filePath, 'utf8');
    return data.trim().split('\n').filter(Boolean).map(line => {
      try { return JSON.parse(line); } catch { return null; }
    }).filter(Boolean);
  } catch {
    return [];
  }
}

function appendJsonl(filePath, data) {
  try {
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.appendFileSync(filePath, JSON.stringify(data) + '\n', 'utf8');
  } catch {}
}

function log(message, level = 'info') {
  const timestamp = new Date().toISOString();
  const prefix = `[evolution-train][${level}]`;
  console.log(`${timestamp} ${prefix} ${message}`);
}

// ── 学习率调度 ──────────────────────────────────────────────────────────────────

function getEditBudget(epoch) {
  const { mode, maxEdits, minEdits, totalEpochs } = LR_CONFIG;

  switch (mode) {
    case 'constant':
      return maxEdits;
    case 'linear':
      return Math.max(minEdits, Math.round(maxEdits * (1 - epoch / totalEpochs)));
    case 'cosine':
      return Math.max(
        minEdits,
        Math.round(
          minEdits + 0.5 * (maxEdits - minEdits) *
          (1 + Math.cos(Math.PI * epoch / totalEpochs))
        )
      );
    default:
      return maxEdits;
  }
}

// ── 反思阶段 ──────────────────────────────────────────────────────────────────

function reflect(observations, currentSkill) {
  // 分析观察数据，识别模式
  const patterns = {
    frequent_edits: {},
    skill_triggers: {},
    tool_usage: {},
    file_types: {},
    session_scores: [],
  };

  for (const obs of observations) {
    // 统计频繁编辑的文件
    if (obs.file_path) {
      patterns.frequent_edits[obs.file_path] =
        (patterns.frequent_edits[obs.file_path] || 0) + 1;
    }

    // 统计 skill 触发
    if (obs.skill_triggered) {
      patterns.skill_triggers[obs.skill_triggered] =
        (patterns.skill_triggers[obs.skill_triggered] || 0) + 1;
    }

    // 统计工具使用
    patterns.tool_usage[obs.tool] =
      (patterns.tool_usage[obs.tool] || 0) + 1;

    // 统计文件类型
    if (obs.file_ext) {
      patterns.file_types[obs.file_ext] =
        (patterns.file_types[obs.file_ext] || 0) + 1;
    }
  }

  return patterns;
}

// ── 提议阶段 ──────────────────────────────────────────────────────────────────

function proposeEdits(patterns, currentSkill, editBudget) {
  const edits = [];

  // 基于模式生成编辑建议
  // 1. 如果某个文件被频繁编辑，可能需要改进相关 skill
  const frequentFiles = Object.entries(patterns.frequent_edits)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3);

  for (const [file, count] of frequentFiles) {
    if (count >= 3) {
      edits.push({
        op: 'append',
        content: `\n\n## 常用文件\n\n- \`${file}\` — 被编辑 ${count} 次，可能是常用文件`,
        reasoning: `文件 ${file} 被频繁编辑（${count} 次），添加到常用文件列表`,
        confidence: Math.min(0.9, 0.5 + count * 0.1),
        support_count: count,
      });
    }
  }

  // 2. 如果某个 skill 被频繁触发，可能需要优化
  const frequentSkills = Object.entries(patterns.skill_triggers)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3);

  for (const [skill, count] of frequentSkills) {
    if (count >= 2 && !skill.startsWith('editing:')) {
      edits.push({
        op: 'append',
        content: `\n\n## 常用 Skill\n\n- \`${skill}\` — 被触发 ${count} 次`,
        reasoning: `Skill ${skill} 被频繁触发（${count} 次），添加到常用列表`,
        confidence: Math.min(0.8, 0.4 + count * 0.1),
        support_count: count,
      });
    }
  }

  // 限制编辑数量
  return edits.slice(0, editBudget);
}

// ── 验证阶段 ──────────────────────────────────────────────────────────────────

function validateEdits(edits, observations) {
  // 简单的验证：基于置信度和支持数
  const validated = edits.filter(edit => {
    // 置信度阈值
    if (edit.confidence < 0.5) return false;
    // 支持数阈值
    if (edit.support_count < 2) return false;
    return true;
  });

  return {
    accepted: validated,
    rejected: edits.filter(e => !validated.includes(e)),
    score: validated.length / Math.max(1, edits.length),
  };
}

// ── 应用阶段 ──────────────────────────────────────────────────────────────────

function applyEdits(skillPath, edits) {
  if (!fs.existsSync(skillPath)) {
    log(`Skill file not found: ${skillPath}`, 'warn');
    return false;
  }

  let content = fs.readFileSync(skillPath, 'utf8');

  for (const edit of edits) {
    switch (edit.op) {
      case 'append':
        content = content.trimEnd() + '\n' + edit.content;
        break;
      case 'insert_after':
        if (edit.target && content.includes(edit.target)) {
          const idx = content.indexOf(edit.target) + edit.target.length;
          content = content.slice(0, idx) + '\n' + edit.content + content.slice(idx);
        }
        break;
      case 'replace':
        if (edit.target && content.includes(edit.target)) {
          content = content.replace(edit.target, edit.content);
        }
        break;
      case 'delete':
        if (edit.target && content.includes(edit.target)) {
          content = content.replace(edit.target, '');
        }
        break;
    }
  }

  // 保存改进后的 skill
  const backupPath = skillPath + `.bak.${Date.now()}`;
  fs.copyFileSync(skillPath, backupPath);
  fs.writeFileSync(skillPath, content, 'utf8');

  log(`Applied ${edits.length} edits to ${skillPath}`, 'info');
  log(`Backup saved to ${backupPath}`, 'info');

  return true;
}

// ── 训练循环 ──────────────────────────────────────────────────────────────────

function train(projectId, epoch) {
  log(`Starting training for project ${projectId}, epoch ${epoch}`, 'info');

  const projectDir = path.join(LEARNING_DIR, 'projects', projectId);
  const observationsFile = path.join(projectDir, 'observations.jsonl');
  const epochDir = path.join(projectDir, 'epochs', `epoch_${String(epoch).padStart(3, '0')}`);

  // 1. 读取观察数据
  const observations = readJsonl(observationsFile);
  if (observations.length < 10) {
    log(`Not enough observations (${observations.length}), skipping training`, 'info');
    return;
  }

  log(`Read ${observations.length} observations`, 'info');

  // 2. 获取编辑预算
  const editBudget = getEditBudget(epoch);
  log(`Edit budget for epoch ${epoch}: ${editBudget}`, 'info');

  // 3. 反思阶段
  const patterns = reflect(observations);
  log(`Identified patterns: ${Object.keys(patterns.frequent_edits).length} frequent files, ${Object.keys(patterns.skill_triggers).length} skill triggers`, 'info');

  // 保存反思结果
  writeJson(path.join(epochDir, 'reflections.json'), patterns);

  // 4. 提议阶段
  // 读取当前 skill（这里以 fix-bug 为例，实际应该遍历所有 skill）
  const skillPath = path.join(SKILLS_DIR, 'fix-bug', 'SKILL.md');
  const currentSkill = fs.existsSync(skillPath) ? fs.readFileSync(skillPath, 'utf8') : '';

  const proposedEdits = proposeEdits(patterns, currentSkill, editBudget);
  log(`Proposed ${proposedEdits.length} edits`, 'info');

  // 保存提议
  writeJson(path.join(epochDir, 'proposals.json'), proposedEdits);

  // 5. 验证阶段
  const validation = validateEdits(proposedEdits, observations);
  log(`Validation: ${validation.accepted.length} accepted, ${validation.rejected.length} rejected`, 'info');

  // 保存验证结果
  writeJson(path.join(epochDir, 'validation.json'), validation);

  // 6. 应用阶段
  if (validation.accepted.length > 0) {
    const applied = applyEdits(skillPath, validation.accepted);

    // 保存 skill 快照
    if (applied && fs.existsSync(skillPath)) {
      const snapshotPath = path.join(epochDir, 'skill_snapshot.md');
      fs.copyFileSync(skillPath, snapshotPath);
    }
  }

  // 7. 更新训练状态
  const stateFile = path.join(projectDir, 'training_state.json');
  const state = readJson(stateFile) || {};
  state.last_training = new Date().toISOString();
  state.epoch = epoch;
  state.last_edit_budget = editBudget;
  state.last_accepted_edits = validation.accepted.length;
  state.last_rejected_edits = validation.rejected.length;
  writeJson(stateFile, state);

  // 记录进化日志
  appendJsonl(path.join(LEARNING_DIR, 'global', 'evolution_log.jsonl'), {
    timestamp: new Date().toISOString(),
    project_id: projectId,
    epoch,
    observations: observations.length,
    proposed: proposedEdits.length,
    accepted: validation.accepted.length,
    rejected: validation.rejected.length,
  });

  log(`Training completed for epoch ${epoch}`, 'info');
}

// ── 主入口 ─────────────────────────────────────────────────────────────────────

function main() {
  const args = process.argv.slice(2);
  let projectId = null;
  let epoch = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--project' && args[i + 1]) {
      projectId = args[i + 1];
      i++;
    }
    if (args[i] === '--epoch' && args[i + 1]) {
      epoch = parseInt(args[i + 1], 10);
      i++;
    }
  }

  if (!projectId) {
    log('Missing --project argument', 'error');
    process.exit(1);
  }

  if (!epoch) {
    // 从训练状态读取当前 epoch
    const stateFile = path.join(LEARNING_DIR, 'projects', projectId, 'training_state.json');
    const state = readJson(stateFile) || {};
    epoch = (state.epoch || 0) + 1;
  }

  try {
    train(projectId, epoch);
  } catch (err) {
    log(`Training failed: ${err.message}`, 'error');
    if (process.env.P_SKILLS_DEBUG) {
      console.error(err);
    }
    process.exit(1);
  }
}

main();
