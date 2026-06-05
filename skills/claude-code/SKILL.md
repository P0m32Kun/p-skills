---
name: claude-code
description: >
  Use when working with Claude Code specifically — hooks, rules, and skills for deep Claude Code optimization.
  Use when user says "Claude Code优化", "hooks配置", "安装hooks".
---

# Claude Code 优化模块

## Overview

Claude Code 专用增强层：3 个 hooks（上下文监控、质量门禁、skill 编辑追踪）、4 个 skills、3 个 rules。只在 Claude Code 环境中生效。

## When to Use

- 需要配置 Claude Code hooks
- 需要安装或管理 Claude Code 优化模块
- 使用 Claude Code 进行开发时（自动生效）

**何时不用**：
- 使用其他 coding agent（pi、Cursor、Codex 等）
- 不需要 Claude Code 特有的优化

> 专门为 Claude Code 设计的 hooks、rules 和 skills，提升开发效率和代码质量。

## 模块总览

```
claude-code/
├── SKILL.md              ← 本文件（入口）
├── install.sh            ← 安装脚本
├── hooks/
│   └── scripts/
│       ├── context-monitor.js     — 上下文监控（警告高工具调用、循环检测、大范围修改）
│       ├── quality-gate.js        — 质量门禁（编辑后自动运行 linter/formatter）
│       └── meta-skill-update.js   — Skill 编辑追踪（记录到学习系统）
├── skills/
│   ├── de-sloppify.md             — 代码清理清单（10 步）
│   ├── context-audit.md           — 上下文窗口审计
│   ├── model-routing.md           — 模型路由决策矩阵
│   └── continuous-learning.md     — 持续学习系统说明
└── rules/
    ├── coding-style.md            — 编码风格规范
    ├── git-workflow.md            — Git 工作流规范
    └── agent-behavior.md          — Agent 行为规范
```

## Hooks 说明（3 个）

### context-monitor.js（PostToolUse）

监控工具调用，在以下情况发出警告：

| 触发条件 | 阈值 | 警告内容 |
|---------|------|---------|
| 工具调用总数过高 | > 50 次 | 建议 /compact |
| 同一工具连续调用 | 3 次 | 疑似循环 |
| 修改文件数过多 | > 15 个 | 范围过大提醒 |

### quality-gate.js（PostToolUse）

每次 Edit/Write/MultiEdit 后自动检测：

- JS/TS: biome / prettier / eslint
- Python: ruff / black
- Go: go vet / gofmt
- Rust: cargo check / cargo fmt
- Markdown: markdownlint

发现问题时输出警告（不阻断）。

### meta-skill-update.js（PostToolUse）

记录对 skill 文件的编辑到 `~/.p-skills/learning/meta-observations.jsonl`：

- 只追踪 `skills/*/SKILL.md` 和 `skills/*/` 下的文件编辑
- 记录：时间戳、文件路径、编辑类型、所在 section、session ID
- 每 10 次观察自动生成分析报告到 `meta.md`
- 支持 `--analyze` 手动触发分析

## Skills 说明（4 个）

| Skill | 用途 | 触发词 |
|-------|------|--------|
| de-sloppify | 实现完成后的 10 步清理清单 | "清理代码", "code cleanup" |
| context-audit | 上下文窗口使用分析和优化建议 | "上下文审计", "token usage" |
| model-routing | 根据任务复杂度选择 Haiku/Sonnet/Opus | "模型选择", "用哪个模型" |
| continuous-learning | 查看和管理学习到的模式 | "学习模式", "查看学习" |

## Rules 说明（3 个）

| Rule | 范围 |
|------|------|
| coding-style.md | 编码原则（不可变性、KISS、DRY、YAGNI）、文件组织、命名、错误处理 |
| git-workflow.md | 分支命名、Conventional Commits、禁止操作、PR 标准 |
| agent-behavior.md | 先调查后编辑、不削弱配置、破坏性操作需确认、质量底线 |

## 安装

```bash
# 安装 hooks 和 rules
bash ~/.p-skills/skills/claude-code/install.sh

# 卸载
bash ~/.p-skills/skills/claude-code/install.sh --uninstall
```

安装内容：
- 合并 hooks 到 `~/.claude/hooks.json`（不覆盖已有配置）
- 创建 `~/.p-skills/gateguard/` 目录
- 创建 `~/.p-skills/sessions/` 目录
- 创建 `~/.p-skills/learning/` 目录

## 环境变量控制

| 变量 | 默认值 | 作用 |
|------|--------|------|
| `P_SKILLS_HOOKS_ENABLED` | `1` | 设为 `0` 禁用所有 hooks |
| `P_SKILLS_QUALITY_GATE` | `1` | 设为 `0` 禁用 quality-gate |
| `P_SKILLS_CONTEXT_MONITOR` | `1` | 设为 `0` 禁用 context-monitor |
| `P_SKILLS_META_LEARNING` | `1` | 设为 `0` 禁用 meta-skill-update |

## 与核心系统的关系

本模块是 P-Skills 核心系统的 **Claude Code 专用增强层**：

- 核心系统（`skills/` 根目录）提供通用开发流程 skills，适用于所有 coding agent
- 本模块提供 Claude Code 特有的 hooks 和优化，只在 Claude Code 环境中生效
- 两套 skills 可以同时使用，不冲突
