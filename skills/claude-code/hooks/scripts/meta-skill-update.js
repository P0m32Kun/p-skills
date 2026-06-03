#!/usr/bin/env node
/**
 * Meta Skill Update — PostToolUse hook
 *
 * 追踪 skill 文件的编辑，记录到 meta-observations.jsonl。
 * 用于分析哪些 skill 部分被频繁修改，指导优化方向。
 */

const fs = require('fs');
const path = require('path');

// ── 配置 ─────────────────────────────────────────────────────────────────────

const LEARNING_DIR = path.join(
  process.env.HOME || require('os').homedir(),
  '.p-skills',
  'learning'
);
const OBSERVATIONS_FILE = path.join(LEARNING_DIR, 'meta-observations.jsonl');
const META_REPORT = path.join(LEARNING_DIR, 'meta.md');
const ANALYSIS_THRESHOLD = 10;

// Skill 文件模式
const SKILL_PATTERNS = [
  /skills\/[^/]+\/SKILL\.md$/,
  /skills\/[^/]+\//,
];

// ── 工具函数 ───────────────────────────────────────────────────────────────────

function ensureDir(dir) {
  try {
    fs.mkdirSync(dir, { recursive: true });
  } catch {}
}

function isSkillFile(filePath) {
  if (!filePath) return false;
  return SKILL_PATTERNS.some(p => p.test(filePath));
}

function extractSection(content) {
  if (!content) return 'unknown';
  const match = content.match(/^#+\s+(.+)/m);
  return match ? match[1].trim() : 'body';
}

function appendObservation(obs) {
  ensureDir(LEARNING_DIR);
  try {
    fs.appendFileSync(OBSERVATIONS_FILE, JSON.stringify(obs) + '\n', 'utf8');
  } catch {}
}

function readObservations() {
  try {
    const data = fs.readFileSync(OBSERVATIONS_FILE, 'utf8');
    return data.trim().split('\n').filter(Boolean).map(line => {
      try { return JSON.parse(line); } catch { return null; }
    }).filter(Boolean);
  } catch {
    return [];
  }
}

function runMetaAnalysis(observations) {
  // 按编辑类型统计
  const byType = {};
  // 按文件统计
  const byFile = {};
  // 按 section 统计
  const bySection = {};

  for (const obs of observations) {
    const t = obs.edit_type || 'unknown';
    byType[t] = (byType[t] || 0) + 1;

    const f = obs.file || 'unknown';
    byFile[f] = (byFile[f] || 0) + 1;

    const s = obs.section || 'unknown';
    bySection[s] = (bySection[s] || 0) + 1;
  }

  const lines = [
    '# Meta Skill Edit Analysis',
    '',
    `> Auto-generated at ${new Date().toISOString()}`,
    `> Total observations: ${observations.length}`,
    '',
    '## By Edit Type',
    '',
    '| Edit Type | Count |',
    '|-----------|-------|',
  ];

  for (const [type, count] of Object.entries(byType).sort((a, b) => b[1] - a[1])) {
    lines.push(`| ${type} | ${count} |`);
  }

  lines.push('');
  lines.push('## By File');
  lines.push('');
  lines.push('| File | Count |');
  lines.push('|------|-------|');

  for (const [file, count] of Object.entries(byFile).sort((a, b) => b[1] - a[1])) {
    lines.push(`| ${file} | ${count} |`);
  }

  lines.push('');
  lines.push('## By Section');
  lines.push('');
  lines.push('| Section | Count |');
  lines.push('|---------|-------|');

  for (const [section, count] of Object.entries(bySection).sort((a, b) => b[1] - a[1])) {
    lines.push(`| ${section} | ${count} |`);
  }

  lines.push('');
  lines.push('## Insights');
  lines.push('');

  const topType = Object.entries(byType).sort((a, b) => b[1] - a[1])[0];
  const topFile = Object.entries(byFile).sort((a, b) => b[1] - a[1])[0];
  const topSection = Object.entries(bySection).sort((a, b) => b[1] - a[1])[0];

  if (topType) {
    lines.push(`- Most common edit type: **${topType[0]}** (${topType[1]} times)`);
  }
  if (topFile) {
    lines.push(`- Most edited file: **${topFile[0]}** (${topFile[1]} times)`);
  }
  if (topSection) {
    lines.push(`- Most edited section: **${topSection[0]}** (${topSection[1]} times)`);
  }

  // 趋势分析（如果有足够的数据）
  if (observations.length >= 20) {
    const recentHalf = observations.slice(Math.floor(observations.length / 2));
    const recentByType = {};
    for (const obs of recentHalf) {
      const t = obs.edit_type || 'unknown';
      recentByType[t] = (recentByType[t] || 0) + 1;
    }
    const recentTop = Object.entries(recentByType).sort((a, b) => b[1] - a[1])[0];
    if (recentTop) {
      lines.push(`- Recent trend: **${recentTop[0]}** edits increasing`);
    }
  }

  lines.push('');
  lines.push('## Recommendations');
  lines.push('');

  // 基于分析生成建议
  if (topSection && topSection[1] > 3) {
    lines.push(`- Section "${topSection[0]}" is frequently edited. Consider:`);
    lines.push(`  - Is the content in this section clear enough?`);
    lines.push(`  - Are there common patterns that could be generalized?`);
  }

  if (topFile && topFile[1] > 5) {
    lines.push(`- File "${topFile[0]}" is heavily modified. Consider:`);
    lines.push(`  - Is this skill too complex?`);
    lines.push(`  - Should it be split into smaller skills?`);
  }

  try {
    fs.writeFileSync(META_REPORT, lines.join('\n') + '\n', 'utf8');
  } catch {}
}

// ── 主逻辑 ─────────────────────────────────────────────────────────────────────

function main() {
  // 支持 --analyze 标志手动触发分析
  if (process.argv.includes('--analyze')) {
    const observations = readObservations();
    if (observations.length === 0) {
      console.log('No observations recorded yet.');
      return;
    }
    runMetaAnalysis(observations);
    console.log(`Analysis written to ${META_REPORT} (${observations.length} observations)`);
    return;
  }

  // 从 stdin 读取 hook 输入
  let input;
  try {
    input = JSON.parse(fs.readFileSync('/dev/stdin', 'utf8'));
  } catch {
    return;
  }

  const toolName = input.tool_name || '';
  if (!['Edit', 'Write', 'MultiEdit'].includes(toolName)) return;

  const toolInput = input.input || input.tool_input || {};
  const filePath = toolInput.file_path || toolInput.path || '';

  if (!isSkillFile(filePath)) return;

  // 提取 section 信息
  let section = 'unknown';
  if (toolName === 'Edit' && toolInput.old_string) {
    section = extractSection(toolInput.old_string);
  } else if (toolInput.content) {
    section = extractSection(toolInput.content);
  }

  const observation = {
    timestamp: new Date().toISOString(),
    file: filePath,
    edit_type: toolName,
    section,
    session_id: input.session_id || 'unknown',
    project_id: input.project_id || 'unknown',
  };

  appendObservation(observation);

  // 检查是否需要触发分析
  const observations = readObservations();
  if (observations.length > 0 && observations.length % ANALYSIS_THRESHOLD === 0) {
    runMetaAnalysis(observations);
  }
}

main();
