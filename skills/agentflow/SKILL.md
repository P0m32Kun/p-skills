---
name: agentflow
description: >
  Use when user says "开始开发", "start development", "agentflow", "开始实现",
  "执行流程", "run pipeline", "开始吧", "let's start", "go ahead".
  Use after requirement is clear and user wants to orchestrate codex ↔ Claude Code collaboration.
---

# Agentflow Pipeline

## Overview

agentflow **只负责优化 Codex 与 Claude Code 之间的协作**——薄编排、白盒审计。

- **流程知识在本目录**：`*-contract.md` + `protocol.md`（唯一维护点）
- **agentflow CLI**：状态机、路径注入、verify 执行、协议解析
- codex 与 Claude Code 在 agentflow 监督下按 contract 工作

流水线由 plan 第一行 `PIPELINE: full|minimal` 声明（见 `protocol.md`）。

不负责登录、模型选择、需求讨论或替代任一工具。

## p-skills 原则

`~/.p-skills/` 是唯一能力库，持续打磨、借鉴优秀 skills。详见 `PRINCIPLES.md`：

- **复用** stage skills，contract 只定义 agentflow 落盘格式
- **质量不够**则优化 skill，不在 contract 重写方法论
- 与 `develop-feature` 共用 stage skill 表

## 协作契约（agent 必读）

| 步骤 | 角色 | Contract | 复用 stage skills |
|------|------|----------|-------------------|
| plan | Codex | `plan-contract.md` | openspec, bdd, writing-plans |
| implement | Claude Code | `implement-contract.md` | test-strategy, tdd / fix-bug |
| review | Codex | `review-contract.md` | code-review, verify |
| fix | Claude Code | `fix-contract.md` | fix-bug |

机器协议：`protocol.md`

## When to Use

- 需求已经和用户讨论清楚，准备进入实现阶段
- 用户说"开始吧"、"开始开发"、"执行流程"

**何时不用**：
- 需求还不清楚 → `brainstorming`
- 只是讨论方案 → `brainstorming`
- 用户想手动实现 → 不干预

## 前置条件

- agentflow 已安装
- codex、Claude Code 已安装、已登录、默认模型已选好
- p-skills 在 `~/.p-skills/skills/`
- 目标项目是 git 仓库

## 调用

```bash
agentflow start "<需求描述>" --repo <项目路径>
```

## 审计产物

每次运行在 `.agent-runs/<run-id>/`，见 `protocol.md` 审计产物表。

调优流程：改 `*-contract.md` → 重跑；改 agentflow 只影响编排与校验。

## 常见问题

### Q: 如何调优 plan/验收流程？

A: 编辑本目录下 `plan-contract.md` 或 `review-contract.md`，不要在 agentflow 模板里改。

### Q: agent 未登录

A: 在 codex / Claude Code 中自行解决，agentflow 不处理认证。

### Q: 中断恢复

```bash
agentflow resume <run-id> --repo <项目路径>
```

## 参考

- `protocol.md` — 机器协议与审计产物
- `develop-feature/SKILL.md` — 完整生命周期编排（更广范围）
- `agentflow --help`
