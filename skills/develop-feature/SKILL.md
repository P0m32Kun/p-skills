---
name: develop-feature
description: >
  Use when developing a complete feature from research to release. Orchestrates
  the full workflow: brainstorming → writing-plans → tdd → doc-sync → verify →
  deploy → retrospective. Use when user says "新需求开发", "功能开发", "完整开发流程".
---

# 完整需求开发流程

> 本文档是需求开发的编排器，串联所有阶段和 skill。

## 核心原则

1. **流程强制** — 每个阶段有明确的完成标准，不能跳过
2. **阻断条件** — 前置条件不满足不能进入下一阶段
3. **可回退** — 发现问题可以回退到之前的阶段

## 流程总览

```
Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
   │          │          │           │          │         │          │
brainstorming  │       tdd       doc-sync    verify    deploy    retrospective
               │
          writing-plans
```

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

### 阶段 2：Design（设计）

**使用的 Skill**：`brainstorming`（继续）、`writing-plans`

**目标**：输出设计文档和实施计划

**输入**：调研报告

**输出**：设计文档 + 实施计划

<HARD-GATE>
**阻断条件**：无 spec 不进入 Implement

**检查项**：
- [ ] 设计文档已完成
- [ ] 实施计划已编写
- [ ] 用户已批准设计
</HARD-GATE>

### 阶段 3：Implement（编码）

**使用的 Skill**：`tdd`

**目标**：按实施计划编码，测试通过

**输入**：实施计划

**输出**：通过测试的代码

<HARD-GATE>
**阻断条件**：编译/测试不通过不进入 Doc-Sync

**检查项**：
- [ ] 所有任务已完成
- [ ] 编译通过
- [ ] 测试通过
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

**目标**：用户视角验证功能

**输入**：实现的代码 + 文档

**输出**：验证报告

<HARD-GATE>
**阻断条件**：用户视角验证不通过不进入 Release

**检查项**：
- [ ] 用户验收条件已满足
- [ ] 边界情况已测试
- [ ] 错误处理已验证
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

## 参考

- 各阶段对应的 skill 文件
- `SKILL.md` — 体系总览
