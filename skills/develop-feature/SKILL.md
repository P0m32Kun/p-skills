---
name: develop-feature
description: >
  Use when user says "新需求开发", "功能开发", "完整开发流程", "开发一个功能",
  "测试工作流", "SDD", "BDD", "TDD", "验收", "怎么测", "避免假实现",
  "new feature", "develop feature", "build feature".
---

# 完整需求开发流程

> 本文档是需求开发的编排器，串联所有阶段和 skill。

## Overview

需求开发的编排器，串联 Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective 全流程。每个阶段有明确的完成标准和阻断条件，不能跳过。

## When to Use

- 用户提出新功能需求，需要从零开始开发
- 需求涉及完整开发周期（调研→设计→编码→文档→验证→发布）
- 需要协调多个 skill 的执行顺序

**何时不用**：
- 单纯修复 bug → 用 `fix-bug`
- 只需要写测试 → 用 `tdd`
- 只需要讨论方案 → 用 `brainstorming`

## 核心原则

1. **流程强制** — 每个阶段有明确的完成标准，不能跳过
2. **阻断条件** — 前置条件不满足不能进入下一阶段
3. **可回退** — 发现问题可以回退到之前的阶段

## 流程总览

```
Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
   │          │          │           │          │         │          │
brainstorming  │       tdd       doc-sync    verify    deploy    retrospective
               │          │                      │
          openspec    test-strategy              │
               │      e2e-write                   │
              bdd                               │
          writing-plans                         │
```

**测试方法论嵌套**（Design→Implement→Verify 贯穿，不另起炉灶）：

```
SDD（openspec）→ 验收信号 REQ-x
  └── BDD（bdd）→ 可观察场景 FT-/E2E-
        └── TDD（tdd + test-strategy）→ unit / integration
              └── E2E（e2e-write）+ verify → 真实环境收口
```

项目若有 `docs/conventions/testing*.md` 或场景注册表，Implement/Verify 阶段必读；无则按本流程通用规则执行。

## 阶段详情

### 阶段 1：Research（调研）

**使用的 Skill**：`brainstorming`

**目标**：明确需求背景、技术方案、竞品分析

**输入**：需求描述

**输出**：调研报告

<HARD-GATE>
**阻断条件**：无调研不进入 Design

**检查项**：
- [ ] 需求背景已明确
- [ ] 技术方案已调研
- [ ] 竞品/最佳实践已分析
- [ ] 调研报告已输出
</HARD-GATE>

### 阶段 2：Design（设计 + 验收对齐）

**使用的 Skill**：`openspec`（主）、`bdd`（场景）、`writing-plans`（拆解）

**目标**：先对齐「构建什么」和「可观察行为」，再写 tasks

**输入**：调研报告

**输出**：proposal / spec（含 REQ-x 验收信号）/ tasks（每条挂 `验收: REQ-x`）+ BDD 场景登记

**推荐顺序**：
1. `openspec` Propose — 产出 spec 与 tasks，**每条需求必须有可勾选验收信号**
2. `bdd` Formulation — 将 GWT 场景登记到项目验收文档（或保留在 spec.md）；分配场景 ID（`FT-*` / `E2E-*`）
3. `writing-plans` — tasks 过大时再拆解执行顺序

<HARD-GATE>
**阻断条件**：无验收信号不进入 Implement

**检查项**：
- [ ] spec 中每条 REQ 有验收信号（UI / API / 日志等可观测项）
- [ ] BDD 场景已登记（文档或 spec 内 GWT）
- [ ] tasks.md 每条任务挂 `验收: REQ-x`
- [ ] 用户已批准设计（或等效确认）
</HARD-GATE>

### 阶段 3：Implement（编码 + 测试驱动）

**使用的 Skill**：`test-strategy`（选层）→ `tdd`（垂直切片）→ `e2e-write`（用户流程变更时）

**目标**：按 tasks 红-绿-重构实现；**禁止先堆代码后补测**

**输入**：spec + tasks + BDD 场景

**输出**：通过测试的代码 + 对应测试资产

**编排方式**（按任务特征选择）：
- 不确定测哪层 → 先 `test-strategy`
- 每个 task → `tdd` 垂直切片（一个 failing test → 最小实现 → 重构）
- 影响用户路径 → 同步或更新 E2E（`e2e-write`）；读项目 E2E 约定（若有）
- 任务大多独立 → `subagent-driven-development`；全部独立 → `dispatching-parallel-agents`

<HARD-GATE>
**阻断条件**：编译/测试不通过，或核心逻辑无测试覆盖，不进入 Doc-Sync

**检查项**：
- [ ] 所有 tasks 已完成且对应验收信号有测试或 E2E 映射
- [ ] 编译通过
- [ ] unit/integration 测试通过（非仅 build/typecheck）
- [ ] 用户可见流程有 E2E 或已记录的手工验收步骤
</HARD-GATE>

### 阶段 4：Doc-Sync（文档同步）

**使用的 Skill**：`doc-sync`

**目标**：同步所有相关文档

**输入**：代码变更

**输出**：更新后的文档

**注意**：Bootstrap 会在代码变更后自动检查是否需要文档同步。以下情况必须同步：
- API 接口变更
- 配置项变更
- 依赖变更
- 数据模型变更

纯内部实现可跳过此阶段。

### 阶段 5：Verify（验证）

**使用的 Skill**：`verify`

**目标**：在**真实/类生产环境**从用户视角验收；对照 BDD 场景与 REQ 验收信号逐项勾选

**输入**：实现的代码 + 文档 + BDD 场景表

**输出**：验证报告

<HARD-GATE>
**阻断条件**：用户视角验证不通过不进入 Release

**检查项**：
- [ ] spec 中所有验收信号已勾选
- [ ] BDD 场景（FT-/E2E-）已自动化或手工验收
- [ ] **build/typecheck  alone 不算完成** — 关键流程须在运行环境（Docker/ staging）实测
- [ ] 边界情况与错误态已验证
</HARD-GATE>

### 阶段 6：Release（发布）

**使用的 Skill**：`deploy`

**目标**：发布到生产环境

**输入**：验证通过的代码

**输出**：发布产物

**流程**：
1. 版本号确定
2. 构建和测试
3. 发布部署
4. 验证发布

### 阶段 7：Retrospective（回顾）

**使用的 Skill**：`retrospective`

**目标**：回顾开发过程，持续优化

**输入**：开发过程记录

**输出**：回顾报告 + 优化建议

**流程**：
1. 收集问题
2. 分析根因
3. 输出优化建议

## 阶段状态管理

在开发过程中，跟踪当前阶段：

```markdown
## 当前状态
- 阶段：Implement
- 进度：3/7 任务完成
- 阻塞：无
```

## 小需求合并

对于小需求，可以合并阶段：

- Research + Design → 一个步骤
- Doc-Sync + Verify → 一个步骤

但不能跳过任何阶段的核心检查项。

## Red Flags — STOP

当你有以下任何想法时，**停下来重新检查**：

- "这个需求够简单，跳过 Research"
- "直接开始写代码"
- "spec 心里有数就行"
- "Doc-Sync 之后再说"
- "Verify 用肉眼看看"
- "先 Implement 再 Design 也行"

**所有这些都意味着你正在合理化跳过流程。回到 develop-feature 的第一步。**

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "Research 和 Design 可以跳过" | 可以合并，但不能跳过 |
| "先写代码再补 spec" | 违反铁律：无 spec 不进入 Implement |
| "小改动不用走完整流程" | 流程就是为了防止"小改动"翻车 |
| "测试通过就算 verify" | 测试通过 ≠ 用户验收 |
| "build 绿就算做完" | build 不验证集成、UI、真实依赖 |
| "代码写了很多应该能用" | 无验收信号 + 无 E2E = 假实现 |
| "Doc-Sync 不重要" | 文档过期比没文档更糟 |

## 参考

- `skills/openspec/` — SDD / 验收信号
- `skills/bdd/` — 场景登记
- `skills/test-strategy/`、`skills/tdd/`、`skills/e2e-write/` — 测试实现
- `skills/verify/` — 用户视角收口
- `SKILL.md` — 体系总览
