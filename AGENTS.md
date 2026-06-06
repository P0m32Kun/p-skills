# P-Skills — For Any Coding Agent

> 本文件是 p-skills 对任何 coding agent 的通用入口。
> 借鉴 `CLAUDE.md` / `AGENTS.md` 约定，但**不绑定任何 agent**。

## What is P-Skills

p-skills 是一套 agent-agnostic 的开发方法论 skill 库：

```
Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
```

覆盖完整开发生命周期，可被任何支持 skill/rules 加载机制的 coding agent 使用。

## Core Principles

1. **流程强制** — 每个阶段有明确的完成标准，不能跳过
2. **可验证** — 每个输出必须可验证
3. **可移植** — 不绑定任何 agent，自然语言描述
4. **自包含** — 一个 `SKILL.md` 就是一个完整 skill
5. **Agent-Agnostic** — 只用通用术语，不引用特定工具名

## 给 Agent 的指令

### 加载时

1. **先调 bootstrap skill**（`skills/bootstrap/SKILL.md`）：它建立了发现和使用其他 skill 的规则
2. **读取 `SKILL.md`**：理解完整的 skill 索引和流程
3. **读取 `docs/tools-reference.md`**：把 skill 中的通用术语映射到你本地的工具名

### 运行时

- 在响应任何用户消息前，**先检查是否有适用的 skill**（即使只有 1% 可能）
- 加载适用的 skill，**严格遵循其流程**
- 不要找理由跳过 skill（详见 `skills/bootstrap/SKILL.md` 的 Red Flags）

### Skill 触发关键词

| 用户说的话 | 加载的 skill |
|-----------|------------|
| 设计讨论、方案探索 | `brainstorming` |
| 写实施计划、拆解任务 | `writing-plans` |
| 新需求开发、功能开发 | `develop-feature` |
| 修复 bug、故障排查 | `fix-bug` |
| TDD、测试驱动 | `tdd` |
| BDD、行为驱动、Gherkin | `bdd` |
| SDD、Spec-Driven、OpenSpec、文档驱动、先写spec、propose | `openspec` |
| 测试策略 | `test-strategy` |
| E2E 测试 | `e2e-write` |
| 用户验证、验收 | `verify` |
| 文档同步、更新文档 | `doc-sync` |
| 文档校验 | `doc-validate` |
| 发布部署、版本发布 | `deploy` |
| 回顾、复盘 | `retrospective` |
| 安全调研 | `security-research` |
| PoC 编写、漏洞验证 | `security-poc` |
| 安全工具集成 | `security-integrate` |
| 按 plan 实现、subagent 开发 | `subagent-driven-development` |
| 并行开发、parallel agents | `dispatching-parallel-agents` |
| 创建 skill、编辑 skill | `writing-skills` |

## 仓库结构

```
p-skills/
├── SKILL.md                      ← 体系总览（必读）
├── AGENTS.md                     ← 本文件（任何 agent 的入口）
├── README.md                     ← 人类阅读
├── INSTALL.md                    ← 安装说明
├── DEPENDENCIES.md               ← 依赖清单
├── CONTEXT.md                    ← 领域知识
├── CHANGELOG.md                  ← 变更日志
├── skills/                       ← 所有 skill（扁平）
│   ├── bootstrap/SKILL.md        ← 会话入口（必须先读）
│   ├── brainstorming/SKILL.md
│   ├── writing-plans/SKILL.md
│   ├── develop-feature/SKILL.md
│   ├── fix-bug/SKILL.md
│   ├── tdd/SKILL.md
│   ├── ... (20 个 skill 总计)
│   └── writing-skills/SKILL.md
├── docs/
│   ├── workflows/                ← 人类可读流程图（非 Agent 入口）
│   ├── tools-reference.md        ← 跨 agent 工具等价表
│   ├── best-practices.md
│   └── archive/                  ← 历史文档（不影响当前流程）
├── integrations/                 ← 外部 MCP 工具的 skill
├── tests/triggering/             ← Skill 触发测试框架
└── plugin manifests/             ← 各 agent 的分发 manifest
    ├── .claude-plugin/
    ├── .codex-plugin/
    ├── .cursor-plugin/
    ├── .opencode/
    └── gemini-extension.json
```

## 集成方式（按 harness）

### 项目级集成（推荐）

把以下内容复制到项目的 agent 配置文件（`AGENTS.md` / `CLAUDE.md` / `.cursorrules` 等）：

```markdown
# P-Skills

本项目使用 p-skills 开发方法论。

## 会话启动时

1. 加载 `~/.p-skills/skills/bootstrap/SKILL.md`
2. 遵循 p-skills 的 Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective 流程
3. 在响应前检查适用的 skill

## 工具映射

参考 `~/.p-skills/docs/tools-reference.md` 把 skill 中的通用术语映射到本地工具名。
```

### 全局集成

把 p-skills 安装到 agent 的全局 skill 目录（详见 `INSTALL.md`），让所有项目自动生效。

### Plugin Marketplace

如果你的 agent 支持 plugin marketplace，优先用 marketplace 安装（自动 bootstrap + 自动更新）。详见各 `.xxx-plugin/` 目录。

## 验证集成

安装后发送以下消息验证触发：

> 我要上线一个新的用户注册模块，整个流程你帮我走一遍。

**预期**：agent 自动加载 `develop-feature` skill 并按流程推进。

**没触发？** 检查：
- bootstrap skill 是否在会话启动时被加载
- 工具等价表是否被正确映射
- skill 文件是否在 agent 的搜索路径中

## 兼容性矩阵

p-skills 在以下 agent 上测试过（社区贡献）：

| Agent | 触发测试 | 安装方式 |
|-------|:------:|---------|
| Claude Code | — | `.claude-plugin/` + `/plugin install` |
| Codex CLI / App | — | `.codex-plugin/` + `/plugins` |
| Cursor | — | `.cursor-plugin/` + `/add-plugin` |
| OpenCode | — | `.opencode/INSTALL.md` |
| Gemini CLI | — | `gemini-extension.json` |
| Qoder CLI | — | `install.sh` |
| Aider | — | `install.sh` |
| pi | — | `install.sh` |
| Reasonix | — | `install.sh` |
| Windsurf | — | `install.sh` |
| Cline | — | `install.sh` |
| Continue | — | `install.sh` |

> 如果你在新 agent 上成功集成 p-skills，请提 PR 在本表中加一行。

## 设计哲学

- **不绑定任何 agent** — Skill 内容只用通用术语
- **适配层分离** — 工具映射在 `docs/tools-reference.md`，不在 skill 里
- **Workflow = Orchestrator skill** — Agent 可执行的流程在 `skills/`（如 `develop-feature`）；`docs/workflows/` 仅人类可读
- **分发自如** — 通过 plugin manifest 可注册到各 marketplace
- **可测试** — `tests/triggering/` 框架验证 description 是否让 agent 自动触发

## 参考

- `SKILL.md` — 完整 skill 索引
- `docs/tools-reference.md` — 跨 agent 工具等价表
- `INSTALL.md` — 详细安装说明
- `tests/triggering/` — 触发测试框架
