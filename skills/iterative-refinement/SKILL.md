---
name: iterative-refinement
description: >
  Use when a task needs iterative improvement cycles — running, testing,
  analyzing failures, fixing, and re-running until quality criteria are met.
  Use when user says "迭代优化", "反复修改", "loop until", "keep improving",
  "循环改进", "反复调试", "迭代验证".
---

# 迭代精炼 — Loop Engineering 核心模式

## Overview

**Loop Engineering** 是一种结构化迭代方法：将"做一次→检查→不达标→改进→再检查"的循环显式化、可控化。避免"试一次就交差"或"无限循环无收敛"两个极端。

## 核心原则

1. **显式退出条件** — 每个 loop 必须定义什么时候停（成功 / 最大轮次 / 收益递减）
2. **状态追踪** — 每轮记录 what changed、what passed、what failed
3. **收敛信号** — 连续 N 轮无改善 → 停止并升级（人工介入 / 换策略）
4. **层次分离** — Task Loop（单任务）、Stage Loop（单阶段）、Workflow Loop（跨阶段）各司其职

## 三层 Loop 模型

```
┌─────────────────────────────────────────────────────┐
│  Layer 3: Workflow Loop（跨阶段回退）                  │
│  Verify 失败 → 回退 Implement → 再 Verify            │
├─────────────────────────────────────────────────────┤
│  Layer 2: Stage Loop（阶段内迭代）                     │
│  执行 → 检查 → 分析失败 → 修复 → 再执行               │
├─────────────────────────────────────────────────────┤
│  Layer 1: Task Loop（单任务循环）                      │
│  RED → GREEN → REFACTOR → 质量自检 → 下一个           │
└─────────────────────────────────────────────────────┘
```

### Layer 1: Task Loop

**范围**：单个任务（一个测试行为、一个函数、一个模块）

**模式**：TDD 红绿循环 + 自我反思

```
写失败测试 → 最小实现 → 重构 → 运行测试
    ↑ RED      ↑ GREEN    ↑ REFACTOR
    │          │          │
    └──────────┴──────────┘
         失败则重试
```

**退出条件**：
- ✅ 测试通过 + 代码质量达标 → 下一个任务
- ❌ 连续 3 轮同一测试失败 → 换策略 / 求助

**实现**：参见 `skills/tdd/SKILL.md`

### Layer 2: Stage Loop

**范围**：单个阶段（Verify、Test、Code Review 等）

**模式**：执行→检查→分析→修复→再执行

```
执行阶段 → 检查结果 → 通过？
   ↑          │         │ yes → 进入下一阶段
   │          │         │ no
   │          ↓         ↓
   └──── 分析失败 ←── 修复问题
```

**退出条件**：
- ✅ 所有检查项通过 → 进入下一阶段
- ❌ 连续 3 轮同一问题未改善 → 升级处理
- ❌ 总轮次超过 5 → 强制暂停，人工介入

**实现**：参见各阶段 skill 中的迭代循环段落

### Layer 3: Workflow Loop

**范围**：跨阶段（Verify 失败 → 回退到 Implement）

**模式**：阶段间回退 + 重新推进

```
Research → Design → Implement → Doc-Sync → Verify
                              ↑               │
                              │    失败 ───────┘
                              │    （带失败原因）
                              └────────────────┘
```

**退出条件**：
- ✅ Verify 通过 → Release
- ❌ 同一 Verify 失败点连续 3 次回退 → 重新 Design
- ❌ 总回退次数超过 5 → 停止，人工介入

**实现**：参见 `skills/develop-feature/SKILL.md`

## Loop 控制参数

每个 loop 使用以下参数控制行为：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `max_iterations` | 3-5 | 最大迭代轮次 |
| `convergence_threshold` | 1 | 连续 N 轮无改善 → 停止 |
| `escalation_action` | 求助用户 | 停止后的行为 |
| `state_tracking` | 必须 | 每轮记录变化 |

## 状态追踪格式

每轮迭代必须记录：

```markdown
## Iteration [N] — [阶段名]

### 本轮变更
- [做了什么]

### 检查结果
- [x] 通过项
- [ ] 失败项 — [原因]

### 与上轮对比
- 改善：[什么变好了]
- 未变：[什么还没改善]
- 退步：[什么变差了]

### 下轮计划
- [要做什么]
```

## Anti-Patterns

- ✗ 试一次就交差，不管质量
- ✗ 无限循环，没有退出条件
- ✗ 每轮做同样的事，期望不同结果
- ✗ 不记录每轮变化，无法判断收敛
- ✗ 跳过分析直接修复（修错方向）
- ✗ 最大轮次设太高，浪费 token

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "试一次差不多就行" | 差不多 = 差很多，loop 就是为了逼近"完全" |
| "循环太浪费 token" | 不循环 = 交付半成品 = 后面花更多 token 修 |
| "我已经知道问题在哪" | 知道 ≠ 修对，loop 验证修复是否真的有效 |
| "设太多限制会卡住" | 限制是保护，防止无限循环消耗资源 |
| "这次很特殊，不需要循环" | 每次都"特殊"，直到出事 |

## 与其他 Skill 的关系

| Skill | Loop 层级 | 关系 |
|-------|----------|------|
| `tdd` | Layer 1 | TDD 红绿循环是 Task Loop 的典型实现 |
| `verify` | Layer 2 | 验证迭代是 Stage Loop 的典型实现 |
| `develop-feature` | Layer 3 | 阶段回退是 Workflow Loop 的典型实现 |
| `fix-bug` | Layer 2 | 诊断迭代是 Stage Loop 的变体 |
| `subagent-driven-development` | Layer 2 | Review-retry 是 Stage Loop 的变体 |

## 参考

- [Loop Engineering for AI Coding Agents](https://www.mindstudio.ai/blog/what-is-loop-engineering-ai-coding-agents) — 概念来源
- [obra/superpowers](https://github.com/obra/superpowers) — HARD-GATE + 反合理化模式
- `skills/tdd/` — Task Loop 实现
- `skills/verify/` — Stage Loop 实现
- `skills/develop-feature/` — Workflow Loop 实现
