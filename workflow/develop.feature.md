---
name: develop.feature
description: 完整需求开发流程编排器
version: 1.0.0
tags: [workflow, orchestrator, feature]
triggers:
  - "新需求开发"
  - "功能开发"
  - "完整开发流程"
inputs:
  - name: requirement
    description: 需求描述
    required: true
outputs:
  - name: release_artifact
    description: 发布产物
---

# 完整需求开发流程

> 本文档是需求开发的编排器，串联所有阶段和 skill。

## 流程总览

```
Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
   │          │          │           │          │         │          │
安全调研    设计文档    编码+测试    文档同步    用户验证    发布部署    回顾优化
```

## 阶段详情

### 阶段 1：Research（调研）

**目标**：明确需求背景、技术方案、竞品分析

**使用的 Skill**：
- `security/research.md` — 安全工具/方案调研（如涉及安全）

**输入**：需求描述

**输出**：调研报告

**阻断条件**：无调研不进入 Design

**流程**：
1. 理解需求背景和目标
2. 调研技术方案和工具
3. 分析竞品和最佳实践
4. 输出调研报告

---

### 阶段 2：Design（设计）

**目标**：输出详细的设计文档（spec）

**使用的 Skill**：
- superpowers 的 `brainstorming` — 设计讨论
- superpowers 的 `writing-plans` — 实施计划
- `docs/templates/feature.md` — 功能文档模板
- `docs/templates/architecture.md` — 架构文档模板

**输入**：调研报告

**输出**：设计文档（spec）

**阻断条件**：无 spec 不进入 Implement

**流程**：
1. 使用 brainstorming 进行设计讨论
2. 使用 writing-plans 制定实施计划
3. 按模板输出设计文档
4. 评审设计文档

---

### 阶段 3：Implement（编码）

**目标**：编写可运行的代码 + 测试

**使用的 Skill**：
- `testing/strategy.md` — 测试策略选择
- mattpocock 的 `tdd` — 测试驱动开发
- `testing/e2e-write.md` — E2E 测试编写

**输入**：设计文档

**输出**：可运行代码 + 测试

**阻断条件**：编译/测试不通过不进入 Doc-Sync

**流程**：
1. 使用 test-strategy 制定测试计划
2. 使用 TDD 进行开发（红-绿-重构）
3. 编写单元测试和集成测试
4. 编写 E2E 测试（如需要）
5. 确保所有测试通过

---

### 阶段 4：Doc-Sync（文档同步）

**目标**：同步更新所有相关文档

**使用的 Skill**：
- `docs/sync.md` — 文档同步
- `docs/validate.md` — 文档一致性校验

**输入**：代码变更 diff

**输出**：更新后的文档

**阻断条件**：文档未同步不进入 Verify

**流程**：
1. 使用 doc-sync 同步文档
2. 使用 doc-validate 校验一致性
3. 修复所有不一致问题

---

### 阶段 5：Verify（验证）

**目标**：从用户视角验证功能是否真正实现

**使用的 Skill**：
- `testing/verify.md` — 用户视角功能验证

**输入**：功能代码 + 文档

**输出**：验证报告

**阻断条件**：用户视角验证不通过不进入 Release

**流程**：
1. 列出用户验收条件
2. 执行 E2E 测试
3. 手动验证（如需要）
4. 输出验证报告
5. 修复发现的问题（可回退到 Implement）

---

### 阶段 6：Release（发布）

**目标**：发布部署

**使用的 Skill**：
- `release/deploy.md` — 发布部署流程

**输入**：验证通过的代码

**输出**：发布产物

**流程**：
1. 确定版本号
2. 构建 Docker 镜像
3. 推送到镜像仓库
4. 更新 CHANGELOG
5. 创建 Git tag + GitHub Release

---

### 阶段 7：Retrospective（回顾）

**目标**：回顾开发过程，持续优化 skill 体系

**使用的 Skill**：
- `workflow/retrospective.md` — 开发回顾与优化

**输入**：开发过程记录

**输出**：回顾报告 + 优化建议

**流程**：
1. 收集问题（工具失败、报错、踩坑、skill 评估）
2. 分析根因
3. 量化影响（时间、token）
4. 输出优化建议
5. 更新 skill（如需要）

**何时执行**：
- 每个需求开发完成后
- 开发过程中遇到重大阻碍时
- 定期回顾（如每周）

## 阶段状态管理

每个阶段有三种状态：

- **pending** — 未开始
- **in_progress** — 进行中
- **completed** — 已完成

状态转换规则：
- 前一阶段 completed 后，下一阶段才能 in_progress
- 阻断条件未满足时，不能标记为 completed
- Verify 阶段可回退到 Implement（状态重置为 in_progress）

## 小需求合并

对于小需求，可合并阶段：

- Research + Design → 一个步骤
- Doc-Sync + Verify → 一个步骤

合并条件：
- 变更范围小（< 100 行代码）
- 不涉及架构变更
- 不涉及安全敏感区域

## 参考
- `SKILL.md` — 体系总览
- 各阶段对应的 skill 文件
