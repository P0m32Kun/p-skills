---
name: p-skills
description: >
  Use when working on any development task — feature work, bug fixes, TDD,
  documentation, deployment, or security work. This is the entry skill for the
  p-skills methodology; load it to discover and dispatch to more specific skills.
---

# P-Skills — 结构化开发技能体系

> 覆盖完整开发生命周期的 skill 仓库，适用于各种 coding agent（Claude Code / Cursor / Codex / OpenCode / pi / Aider 等）。

## ⚡ 加载时自动更新检查

在 skill 仓库根目录下执行：

```bash
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "SKIP_UPDATE:not_a_git_repo"; exit 0
fi
LOCAL=$(git rev-parse HEAD 2>/dev/null) || { echo "SKIP_UPDATE:git_error"; exit 0; }
REMOTE=$(git rev-parse @{u} 2>/dev/null) || { echo "SKIP_UPDATE:no_upstream"; exit 0; }
if [ "$LOCAL" != "$REMOTE" ]; then
  echo "UPDATE_AVAILABLE:$(git rev-list HEAD..@{u} --count 2>/dev/null || echo '?')"
else
  echo "UP_TO_DATE"
fi
```

`UPDATE_AVAILABLE:N` → `git pull --rebase --autostash`；`UP_TO_DATE` 或 `SKIP_UPDATE:*` → 跳过。

## 核心理念

1. **流程强制** — 每个阶段有明确的完成标准，不能跳过
2. **可移植** — 不绑定特定 coding agent，用自然语言描述
3. **Agent-Agnostic** — 只用通用术语，不引用特定工具名；工具映射在 `docs/tools-reference.md`
4. **自包含** — 一个 `SKILL.md` 就是一个完整 skill
5. **通用优先** — 覆盖通用开发流程，安全作为专项模块
6. **最小 frontmatter** — 只用 `name` + `description`，让 description 承担触发职责

## 开发流程

```
Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
   │          │          │           │          │         │          │
需求调研    设计文档    编码+测试    文档同步    用户验证    发布部署    回顾优化
```

### 阻断条件

| 阶段 | 阻断条件 |
|------|---------|
| Research | 无调研不进入 Design |
| Design | 无 spec 不进入 Implement |
| Implement | 编译/测试不通过不进入 Doc-Sync |
| Doc-Sync | 文档未同步不进入 Verify |
| Verify | 用户视角验证不通过不进入 Release |

允许：回退（Verify → Implement）、小需求合并（Research + Design）。

## Skill 文件格式

### Frontmatter（最小化规范）

**只允许两个字段**：`name` 和 `description`。

```yaml
---
name: skill-name              # 必填，kebab-case，必须等于目录名
description: >                # 必填，<500 chars
  Use when [具体触发条件、症状、场景].
  Use when user says "关键词1", "关键词2".
---
```

**Description 写作规则（借鉴 obra/superpowers 实测结论）：**

- ✅ 必须以 "Use when…" 开头，只描述**触发条件**
- ❌ **不要总结 skill 的流程**（实测表明 agent 会走捷径只看 description，跳过正文）
- ✅ 包含具体症状、关键词、用户可能说的话
- ✅ 第三人称（被注入到系统提示）
- ✅ 控制在 500 字符以内

**示例：**

```yaml
# ❌ 坏：总结了流程，agent 可能跳过正文
description: Use when fixing bugs - performs root cause analysis, plans fix, implements, tests, and merges

# ✅ 好：只描述触发条件
description: Use when fixing bugs, debugging issues, or troubleshooting errors. Use when user says "修复bug", "fix bug", "hotfix".
```

### 文件体结构

```markdown
# Skill 标题

## Overview
1-2 句话说明核心原则。

## When to Use
（可选）流程图仅在决策非显而易见时使用

- 触发场景列表
- 何时不用

## Process / Core Pattern
具体流程或代码模式

## Red Flags — STOP
哪些想法说明你正在合理化跳过流程

## Common Rationalizations
| 借口 | 现实 |
|------|------|

## Completion Checklist
- [ ] 可验证的完成条件

## References
- 相关文件、外部链接
```

### 可移植性约束

- **不依赖特定 agent 的工具调用语法** — 只用通用术语（"读文件"、"执行命令"、"派 subagent"），具体工具名由 agent 运行时按 `docs/tools-reference.md` 映射
- **不引用特定 agent 的配置文件**（如 `CLAUDE.md` / `AGENTS.md` / `.cursorrules`）— 用"项目级 agent 配置文件"代替
- 输入输出用自然语言或 JSON Schema
- 每个 skill 自包含（`SKILL.md` + 可选 supporting files）

## Skill 索引

**所有 skill 位于 `skills/` 目录，每个子目录一份 SKILL.md**：

### 开发流程

| Skill | 路径 | 触发条件 |
|-------|------|---------|
| bootstrap | `skills/bootstrap/` | 会话开始 |
| brainstorming | `skills/brainstorming/` | 设计讨论、方案探索、需求澄清 |
| writing-plans | `skills/writing-plans/` | 编写实施计划、拆解任务 |
| develop-feature | `skills/develop-feature/` | 新需求开发、完整开发流程 |
| fix-bug | `skills/fix-bug/` | 修复 bug、故障排查、hotfix |
| code-review | `skills/code-review/` | 代码评审、检查修改、code review |
| code-cleanup | `skills/code-cleanup/` | 清理死代码、删除未使用文件、重构 |
| retrospective | `skills/retrospective/` | 回顾总结、复盘 |

### 测试与验证

| Skill | 路径 | 触发条件 |
|-------|------|---------|
| tdd | `skills/tdd/` | TDD、测试驱动、红绿重构 |
| openspec | `skills/openspec/` | SDD、Spec-Driven、OpenSpec、文档驱动、先写spec、propose、先定方案再实现 |
| bdd | `skills/bdd/` | BDD、行为驱动、Gherkin、Three Amigos、Example Mapping |
| test-strategy | `skills/test-strategy/` | 测试策略、选择测试层级 |
| e2e-write | `skills/e2e-write/` | 编写 E2E 测试、Playwright |
| verify | `skills/verify/` | 用户视角验证、验收测试 |

### 文档

| Skill | 路径 | 触发条件 |
|-------|------|---------|
| doc-sync | `skills/doc-sync/` | 文档同步、更新文档 |
| doc-validate | `skills/doc-validate/` | 文档校验、一致性检查 |

### 安全专项

| Skill | 路径 | 触发条件 |
|-------|------|---------|
| security-research | `skills/security-research/` | 安全调研、安全工具 |
| security-poc | `skills/security-poc/` | PoC 编写、漏洞验证 |
| security-integrate | `skills/security-integrate/` | 安全工具集成到 CI/CD |

### 发布

| Skill | 路径 | 触发条件 |
|-------|------|---------|
| deploy | `skills/deploy/` | 发布部署、版本发布、Docker/npm/pip |

### 元技能

| Skill | 路径 | 触发条件 |
|-------|------|---------|
| writing-skills | `skills/writing-skills/` | 创建/编辑/改进 skill |

### Subagent 编排

| Skill | 路径 | 触发条件 |
|-------|------|---------|
| subagent-driven-development | `skills/subagent-driven-development/` | 按 plan 顺序派 subagent 实现 |
| dispatching-parallel-agents | `skills/dispatching-parallel-agents/` | 并行派多个 subagent 做独立任务 |

### Claude Code 专项优化

| Skill | 路径 | 触发条件 |
|-------|------|---------|
| claude-code | `skills/claude-code/` | Claude Code 优化、hooks 配置、安装 hooks |

包含：10 个 hooks（gateguard 事实强制、配置保护、质量门禁、上下文监控、学习系统）、3 个 rules（编码风格、Git 工作流、Agent 行为）、4 个 skills（de-sloppify、context-audit、model-routing、continuous-learning）。

详见 `skills/claude-code/SKILL.md`

### 集成 Skills（外部 MCP 工具，详见 `integrations/README.md`）

| Skill | 路径 | 用途 |
|-------|------|------|
| recall / remember / recap / handoff / forget / commit-context / commit-history / session-history | `integrations/agentmemory/` | 持久记忆管理 |
| codegraph-usage | `integrations/codegraph/` | 代码图谱分析 |
| semble-search | `integrations/semble/` | 语义代码搜索 |

## 设计来源

| 仓库 | 学到的理念 |
|------|-----------|
| [obra/superpowers](https://github.com/obra/superpowers) | HARD-GATE、反合理化、最小 frontmatter、subagent 编排、触发测试 |
| [mattpocock/skills](https://github.com/mattpocock/skills) | 扁平 namespace、description 触发、渐进式披露 |
| [gstack](https://github.com/garrytan/gstack) | 模板化、版本管理 |
| [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | 行为准则、防 LLM 错误 |
| [microsoft/SkillOpt](https://github.com/microsoft/SkillOpt) | ReflACT 流水线、skill 文档作为可训练状态、Validation Gate、Learning Rate 调度 |

详见 `docs/best-practices.md` 和 `docs/self-evolution-design.md`。

## 相关文档

- `AGENTS.md` — 任何 coding agent 的通用入口（推荐先读）
- `INSTALL.md` — 安装说明（供 agent 自动安装）
- `DEPENDENCIES.md` — 依赖检查清单
- `CONTEXT.md` — 领域知识与术语表
- `CHANGELOG.md` — 变更日志
- `docs/tools-reference.md` — 跨 agent 工具等价表（适配层）
- `docs/best-practices.md` — 优秀 skill 设计模式
- `docs/analysis.md` — 竞品分析
- `docs/self-evolution-design.md` — 自进化系统设计（基于 SkillOpt）
- `.claude-plugin/README.md` — 多 harness plugin manifest 说明
- `tests/triggering/README.md` — Skill 触发测试框架
