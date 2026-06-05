---
name: writing-skills
description: >
  Use when creating, editing, or improving a skill.
  Use when user says "写一个 skill", "新建 skill", "创建一个技能",
  "writing skill", "create skill", "改进 skill", "改一下 skill".
---

# Writing Skills — P-Skills 元技能

> **创建 skill 就是把 TDD 应用到流程文档上。**

<HARD-GATE>
**NO SKILL WITHOUT A FAILING TEST FIRST.**

没看到 agent 在没有 skill 时失败，就不知道 skill 该教什么。先跑基线，再写 skill。
</HARD-GATE>

## Overview

Skill 是**可复用的技术/模式/工具的参考手册**，不是"我某次怎么解决问题"的故事。

**铁律**：先写测试场景 → 看 agent 自然行为（RED）→ 写 skill → 看 agent 服从（GREEN）→ 堵漏洞（REFACTOR）。

## When to Use

**Create when:**
- 技术对你来说不显而易见
- 跨项目会再次用到
- 模式足够通用（不是项目特有）

**Don't create for:**
- 一次性解决方案
- 标准做法（别处已有文档）
- 项目特有约定（写到项目级 agent 配置文件，如 `<project>/AGENTS.md` 或对应 harness 的项目规则文件）
- 能用正则/校验强制的机械约束（自动化，别写文档）

## Skill 类型

| 类型 | 定义 | 示例 |
|------|------|------|
| **Technique** | 具体步骤的方法 | TDD、systematic-debugging |
| **Pattern** | 思考问题的方式 | flatten-with-flags |
| **Reference** | API/语法/工具文档 | deploy（npm/pip/docker 场景） |
| **Orchestrator** | 串联多个 skill 的流程 | develop-feature、fix-bug |

## Directory Structure

```
skills/
  skill-name/
    SKILL.md              # 主入口（必须）
    supporting-file.*     # 可选：重型参考、脚本、模板
```

**扁平 namespace** — 所有 skill 在同一级。

**拆出独立文件的情况：**
1. 重型参考（100+ 行）— API 文档、语法手册
2. 可复用工具 — 脚本、模板
3. Subagent prompt — implementer-prompt.md、spec-reviewer-prompt.md

**保留在 SKILL.md 内：**
- 原则、概念
- 代码模式（< 50 行）
- 流程图（仅用于非显而易见的决策）

## SKILL.md Structure

### Frontmatter（最小化，只有两个字段）

```yaml
---
name: skill-name              # 必填，kebab-case，= 目录名
description: >                # 必填，<500 chars
  Use when [触发条件、症状、场景].
  Use when user says "关键词1", "关键词2".
---
```

**Description 写作规则：**

- ✅ 以 "Use when…" 开头，只描述触发条件
- ❌ **不要总结 skill 的流程**（实测表明 agent 会走捷径，跳过正文）
- ✅ 包含具体症状、关键词、用户可能说的话
- ✅ 第三人称（被注入系统提示）
- ✅ 技术无关（除非 skill 本身绑定技术）

**示例：**

```yaml
# ❌ 坏：总结了流程
description: Use for TDD - write test first, watch it fail, write minimal code, refactor

# ❌ 坏：太抽象
description: For async testing

# ✅ 好：只描述触发条件
description: Use when implementing any feature or bugfix, before writing implementation code

# ✅ 好：包含症状
description: Use when tests have race conditions, timing dependencies, or pass/fail inconsistently
```

### 文件体模板

```markdown
# Skill 名

## Overview
1-2 句核心原则。一句话可被引用的铁律。

## When to Use
（可选）仅当决策非显而易见时用流程图。
- 适用场景列表
- 何时不用（明确边界）

## Process / Core Pattern
具体步骤、代码对比、示例。

## Verification Checklist
- [ ] 可验证的完成条件

## Red Flags — STOP
哪些想法说明你正在合理化跳过流程（列表）。
**所有这些都意味着：停下来，重新开始。**

## Common Rationalizations
| 借口 | 现实 |
|------|------|
| "太简单了" | 简单代码也会错。测试 30 秒。 |
| "先做 X 再说" | 之前检查。 |

## References
- 相关 skill（用 name，不用路径）
- 外部链接
```

## 行为塑造工具

Skill 不是散文 — 它是**塑造 agent 行为的代码**。使用以下工具防止 agent 找借口：

### `<HARD-GATE>` 标签

用于绝对不能跳过的检查点：

```markdown
<HARD-GATE>
阻断条件：X 不满足不得进入 Y
- [ ] 检查项 1
- [ ] 检查项 2
</HARD-GATE>
```

### `<EXTREMELY-IMPORTANT>` 标签

用于最高优先级的指令（如 bootstrap 里的"必须先检查 skill"）：

```markdown
<EXTREMELY-IMPORTANT>
如果 skill 适用，你没有选择 — 必须使用它。
</EXTREMELY-IMPORTANT>
```

### `<Good>` / `<Bad>` 标签

对比示例：

```markdown
<Good>
// 清晰的命名，测试真实行为
test('retries failed operations 3 times', ...)
</Good>

<Bad>
// 模糊命名，测试 mock 不是代码
test('retry works', ...)
</Bad>
```

### Rationalization Table

记录从基线测试中观察到的 agent 借口：

```markdown
| 借口 | 现实 |
|------|------|
| "太简单，不用测" | 简单代码也会错。30 秒写完测试。 |
| "我记得这个 skill" | Skill 会演进。读当前版本。 |
```

### Red Flags 列表

让 agent 自检正在合理化的信号：

```markdown
## Red Flags — STOP

- 写代码前没写测试
- "先做这一件小事"
- "这次不一样因为..."

**所有这些都意味着：删除代码，从 TDD 重新开始。**
```

## Cross-Referencing

引用其他 skill 时**只用 name**，加上 REQUIRED 标记：

- ✅ `**REQUIRED:** 使用 tdd skill`
- ✅ `**REQUIRED BACKGROUND:** 必须先理解 systematic-debugging`
- ❌ `See skills/testing/tdd.md`（路径硬编码）
- ❌ `@skills/tdd/SKILL.md`（强制加载，浪费 context）

## RED-GREEN-REFACTOR for Skills

### RED：写失败测试（基线）

运行压力场景让 subagent 完成目标任务，**不带 skill**：

- Agent 做了什么选择？
- 用了哪些借口（逐字记录）？
- 哪种压力触发了违规？

这是"看测试失败" — 写 skill 前必须先看到 agent 的自然行为。

### GREEN：写最小 skill

针对观察到的具体借口写 skill。不要为假设场景加内容。

运行同样的场景**带 skill**，agent 应该服从。

### REFACTOR：堵漏洞

Agent 找到新借口？加显式 counter。重复测试直到 bulletproof。

**压力类型：**
- 时间压力："客户在催"
- 沉没成本："已经写了 X 小时"
- 权威压力："老板说可以这样"
- 疲惫压力："深夜最后一个任务"
- 简单性压力："这么小的改动"

## Common Rationalizations for Skipping Testing

| 借口 | 现实 |
|------|------|
| "Skill 明显清晰" | 对你清晰 ≠ 对其他 agent 清晰。测。 |
| "只是参考文档" | 参考也可能有缺口。测检索。 |
| "测试太重了" | 15 分钟测试省几小时调试。 |
| "出问题再测" | 出问题 = agent 不会用。部署前测。 |
| "我有信心" | 过度自信保证出问题。还是要测。 |

## Skill Creation Checklist

**RED Phase:**
- [ ] 创建 3+ 个压力场景（纪律类 skill 组合多种压力）
- [ ] 不带 skill 跑基线，逐字记录 agent 行为
- [ ] 识别失败模式

**GREEN Phase:**
- [ ] name 只用字母、数字、连字符
- [ ] frontmatter 只有 name + description（<1024 chars）
- [ ] description 以 "Use when…" 开头，只描述触发条件
- [ ] 关键词覆盖（错误、症状、工具）
- [ ] Overview 有核心原则
- [ ] 针对基线失败写内容
- [ ] 带 skill 重跑场景，验证 agent 服从

**REFACTOR Phase:**
- [ ] 识别新借口
- [ ] 加显式 counter（纪律类 skill）
- [ ] 完善 rationalization table
- [ ] 创建 red flags 列表
- [ ] 重复测试直到 bulletproof

**Quality:**
- [ ] 流程图仅用于非显而易见决策
- [ ] Quick reference 表格
- [ ] Common mistakes 章节
- [ ] 无叙事性故事
- [ ] Supporting files 只用于工具或重型参考

## Anti-Patterns

### ❌ Narrative Example
"In session 2025-10-03, we found empty projectDir caused..."
**Why bad:** 太具体，不可复用

### ❌ Multi-Language Dilution
example-js.js, example-py.py, example-go.go
**Why bad:** 平庸质量，维护负担

### ❌ Code in Flowcharts
```dot
step1 [label="import fs"];
step2 [label="read file"];
```
**Why bad:** 不能复制粘贴，难读

### ❌ Generic Labels
helper1, helper2, step3
**Why bad:** Label 应该有语义

### ❌ 在 description 里总结流程
**Why bad:** Agent 走捷径，跳过正文

## References

- 各 agent 官方的 skill/prompt authoring 指南（按你使用的 harness 查找）
- `skills/tdd/` — 同一套铁律应用到代码
- `docs/best-practices.md` — 竞品分析与优秀 skill 设计模式
- [obra/superpowers writing-skills](https://github.com/obra/superpowers/tree/main/skills/writing-skills) — 灵感来源
