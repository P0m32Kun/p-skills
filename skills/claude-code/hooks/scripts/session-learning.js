#!/usr/bin/env node
/**
 * Session Learning — SessionStart hook
 *
 * 在会话开始时加载学习到的模式，注入到 agent 上下文中。
 * 让 agent 能够利用历史经验改进表现。
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const crypto = require('crypto');

// ── 配置 ─────────────────────────────────────────────────────────────────────

const LEARNING_DIR = path.join(
  process.env.HOME || require('os').homedir(),
  '.p-skills',
  'learning'
);
const MAX_INSTINCTS = 5;
const MIN_CONFIDENCE = 0.5;

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

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
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

// ── 加载学习数据 ──────────────────────────────────────────────────────────────

function loadProjectInstincts(projectId) {
  const projectDir = path.join(LEARNING_DIR, 'projects', projectId);
  const stateFile = path.join(projectDir, 'training_state.json');
  const state = readJson(stateFile);

  if (!state) return null;

  // 加载最佳 skill 版本
  const bestSkillsDir = path.join(projectDir, 'best_skills');
  const bestSkills = {};

  if (fs.existsSync(bestSkillsDir)) {
    const files = fs.readdirSync(bestSkillsDir).filter(f => f.endsWith('.md'));
    for (const file of files) {
      const skillName = file.replace('.md', '');
      bestSkills[skillName] = fs.readFileSync(
        path.join(bestSkillsDir, file),
        'utf8'
      );
    }
  }

  // 加载最近的反思结果
  const epochsDir = path.join(projectDir, 'epochs');
  let latestReflections = null;

  if (fs.existsSync(epochsDir)) {
    const epochs = fs.readdirSync(epochsDir)
      .filter(d => d.startsWith('epoch_'))
      .sort()
      .reverse();

    if (epochs.length > 0) {
      const reflectionsFile = path.join(epochsDir, epochs[0], 'reflections.json');
      latestReflections = readJson(reflectionsFile);
    }
  }

  // 加载 session 分数历史
  const scoresFile = path.join(projectDir, 'session_scores.jsonl');
  const sessionScores = readJsonl(scoresFile);

  // 计算平均分数
  const avgScore = sessionScores.length > 0
    ? sessionScores.reduce((sum, s) => sum + (s.score || 0), 0) / sessionScores.length
    : 0;

  return {
    project_id: projectId,
    epoch: state.epoch || 0,
    session_count: state.session_count || 0,
    avg_score: avgScore,
    best_skills: bestSkills,
    latest_reflections: latestReflections,
    last_training: state.last_training,
  };
}

function loadGlobalPatterns() {
  const patternsFile = path.join(LEARNING_DIR, 'global', 'meta_patterns.jsonl');
  return readJsonl(patternsFile);
}

// ── 格式化输出 ──────────────────────────────────────────────────────────────────

function formatLearningContext(projectData, globalPatterns) {
  const lines = [];

  lines.push('## 🧠 Learned Patterns');
  lines.push('');

  if (projectData) {
    lines.push(`### Project Statistics`);
    lines.push(`- Epoch: ${projectData.epoch}`);
    lines.push(`- Sessions: ${projectData.session_count}`);
    lines.push(`- Average Score: ${projectData.avg_score.toFixed(2)}`);
    lines.push('');

    if (projectData.latest_reflections) {
      const reflections = projectData.latest_reflections;

      // 常用文件
      const frequentFiles = Object.entries(reflections.frequent_edits || {})
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3);

      if (frequentFiles.length > 0) {
        lines.push('### Frequently Edited Files');
        for (const [file, count] of frequentFiles) {
          lines.push(`- \`${file}\` — ${count} times`);
        }
        lines.push('');
      }

      // 常用 Skill
      const frequentSkills = Object.entries(reflections.skill_triggers || {})
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3);

      if (frequentSkills.length > 0) {
        lines.push('### Frequently Used Skills');
        for (const [skill, count] of frequentSkills) {
          lines.push(`- \`${skill}\` — ${count} times`);
        }
        lines.push('');
      }

      // 工具使用模式
      const toolUsage = Object.entries(reflections.tool_usage || {})
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5);

      if (toolUsage.length > 0) {
        lines.push('### Tool Usage Patterns');
        for (const [tool, count] of toolUsage) {
          lines.push(`- \`${tool}\` — ${count} calls`);
        }
        lines.push('');
      }
    }
  }

  if (globalPatterns && globalPatterns.length > 0) {
    lines.push('### Global Patterns');
    const recentPatterns = globalPatterns.slice(-5);
    for (const pattern of recentPatterns) {
      if (pattern.pattern) {
        lines.push(`- ${pattern.pattern}`);
      }
    }
    lines.push('');
  }

  if (lines.length <= 3) {
    return null; // 没有足够的学习数据
  }

  return lines.join('\n');
}

// ── 主逻辑 ─────────────────────────────────────────────────────────────────────

function main() {
  if (process.env.P_SKILLS_LEARNING === 'off') {
    process.exit(0);
  }

  const projectDir = process.cwd();
  const projectId = getProjectId(projectDir);

  // 加载项目学习数据
  const projectData = loadProjectInstincts(projectId);

  // 加载全局模式
  const globalPatterns = loadGlobalPatterns();

  // 格式化学习上下文
  const learningContext = formatLearningContext(projectData, globalPatterns);

  if (!learningContext) {
    // 没有足够的学习数据，静默退出
    process.exit(0);
  }

  // 输出学习上下文（会被 Claude Code 读取）
  const result = {
    additionalContext: learningContext,
  };

  process.stdout.write(JSON.stringify(result));
}

main();
