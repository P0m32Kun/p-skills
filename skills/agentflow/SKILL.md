---
name: agentflow
description: >
  Use when user says "开始开发", "start development", "agentflow", "开始实现",
  "执行流程", "run pipeline", "开始吧", "let's start", "go ahead".
  Use after requirement is clear and user wants to execute the plan-implement-verify-review pipeline.
---

# Agentflow Pipeline

## Overview

调用 agentflow CLI 执行自动化开发流水线：codex 规划 → opencode 实现 → 验证 → codex 审查。

## When to Use

- 需求已经和用户讨论清楚，准备进入实现阶段
- 用户说"开始吧"、"开始开发"、"执行流程"
- 已经有了明确的需求描述

**何时不用**：
- 需求还不清楚 → 继续和用户讨论
- 只是讨论方案 → 用 `brainstorming`
- 用户想手动实现 → 不干预

## 前置条件

- agentflow 已安装（`go install github.com/P0m32Kun/agentflow/cmd/agentflow@latest`）
- codex 已安装并登录（`codex --help` 验证）
- opencode 已安装并登录（`opencode --help` 验证）
- 目标项目是 git 仓库

## 流程

### 1. 确认需求

在调用 agentflow 之前，确保需求已经明确：

```markdown
## 需求确认清单
- [ ] 用户描述了要实现的功能
- [ ] 技术方案已讨论（或用户说"你来决定"）
- [ ] 验收标准已明确（或可以从需求推导）
- [ ] 用户说"开始吧"或类似表述
```

### 2. 调用 agentflow

```bash
agentflow start "<需求描述>" --repo <项目路径>
```

**关键**：需求描述要完整、具体，因为 agentflow 会把它传给 codex 生成计划。

示例：
```bash
# 好的需求描述
agentflow start "实现用户登录功能，使用 JWT token，支持邮箱和手机号登录" --repo /path/to/project

# 不够具体的需求描述（但也可以）
agentflow start "实现用户登录" --repo /path/to/project
```

### 3. 观察输出

agentflow 会实时输出进度：

```
[10:12:01] RUN created: 20260605-101201-login-feature
[10:12:04] WORKTREE created: ../project-agent-worktrees/20260605-101201-login-feature
[10:12:16] PLANNING started (codex (plan))
[10:13:02] PLAN ready: .agent-runs/.../plan.md
[10:13:03] IMPLEMENTING started (opencode (implement))
[10:18:47] VERIFYING started
[10:18:47] VERIFY passed
[10:22:15] REVIEWING started (codex (review))
[10:27:40] DONE: .agent-runs/.../final-report.md
```

### 4. 处理结果

**成功** (`Succeeded`)：
- 告诉用户开发完成
- 提示查看 worktree 中的代码变更
- 提示合并分支

**阻塞** (`Blocked`)：
- 查看 review 文件了解阻塞原因
- 和用户讨论解决方案
- 可以 `agentflow resume <run-id>` 继续

**失败** (`Failed`)：
- 查看 events.jsonl 了解失败原因
- 和用户讨论是否需要调整需求

### 5. 查看详情

```bash
# 查看状态
agentflow status --repo /path/to/project

# 查看事件日志
agentflow logs <run-id> --repo /path/to/project

# 查看产物
ls .agent-runs/<run-id>/
```

## 模型配置

agentflow 使用 codex 和 opencode 的默认配置。用户需要在各自工具中配置模型：

### Codex 模型配置

```bash
# 环境变量
export CODEX_MODEL=o4-mini

# 或在 codex 命令行
codex --model o4-mini
```

### OpenCode 模型配置

```bash
# 环境变量
export OPENCODE_MODEL=claude-sonnet-4-20250514

# 或在 opencode 配置文件
# opencode.json: {"provider": "anthropic", "model": "claude-sonnet-4-20250514"}
```

## 常见问题

### Q: agentflow 报错 "codex: command not found"

A: codex 未安装或不在 PATH 中。安装：
```bash
npm install -g @openai/codex
```

### Q: agentflow 报错 "opencode: command not found"

A: opencode 未安装。安装：
```bash
npm install -g opencode
```

### Q: 如何查看 agentflow 的运行产物？

A: 产物在 `.agent-runs/<run-id>/` 目录：
- `plan.md` — codex 生成的计划
- `events.jsonl` — 完整事件日志
- `state.json` — 最终状态
- `final-report.md` — 运行报告

### Q: agentflow 运行中途中断了怎么办？

A: 使用 resume 恢复：
```bash
agentflow resume <run-id> --repo /path/to/project
```

## 完成标准

- [ ] agentflow 流水线执行完成
- [ ] 最终状态为 Succeeded/Blocked/Failed 之一
- [ ] 已向用户报告结果
- [ ] 成功时提示用户检查代码变更
- [ ] 失败/阻塞时已分析原因并告知用户

## 参考

- `agentflow --help` — CLI 帮助
- `.agent-runs/` — 运行产物目录
- `docs/go-mvp-implementation-plan.md` — 设计文档
