---
name: develop.feature
description: 完整需求开发流程编排器
version: 1.1.0
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

## 核心原则

1. **流程强制** — 每个阶段有明确的完成标准，不能跳过
2. **可验证** — 每个输出必须可验证，不能依赖主观判断
3. **持续改进** — 每次开发完成后进行回顾，持续优化

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

<HARD-GATE>
**阻断条件**：无调研不进入 Design

**检查项**：
- [ ] 需求背景已明确
- [ ] 技术方案已调研
- [ ] 竞品/最佳实践已分析
- [ ] 调研报告已输出
</HARD-GATE>

**流程**：
1. 理解需求背景和目标
2. 调研技术方案和工具
3. 分析竞品和最佳实践
4. 输出调研报告

**Anti-Patterns**：
- ✗ 跳过调研直接开始编码
- ✗ 只调研一个方案就决定
- ✗ 不看竞品，闭门造车

---

### 阶段 2：Design（设计）

**目标**：输出详细的设计文档（spec）

**使用的 Skill**：
- `workflow/brainstorming.md` — 需求讨论与设计探索
- `docs/templates/feature.md` — 功能文档模板
- `docs/templates/architecture.md` — 架构文档模板

**输入**：调研报告

**输出**：设计文档（spec）

<HARD-GATE>
**阻断条件**：无 spec 不进入 Implement

**检查项**：
- [ ] 设计文档已输出
- [ ] 设计文档已评审
- [ ] 用户已批准设计
</HARD-GATE>

**流程**：
1. 使用 brainstorming 进行设计讨论（澄清需求、探索方案、增量验证）
2. 按模板输出设计文档
3. 设计自检（占位符、一致性、范围、歧义）
4. 用户评审设计文档

**Anti-Patterns**：
- ✗ "这个太简单了，不需要设计"
- ✗ 设计文档过于笼统，没有具体细节
- ✗ 跳过评审直接开始编码

---

### 阶段 3：Implement（编码）

**目标**：编写可运行的代码 + 测试

**使用的 Skill**：
- `workflow/writing-plans.md` — 实施计划编写
- `testing/tdd.md` — 测试驱动开发
- `testing/strategy.md` — 测试策略选择
- `testing/e2e-write.md` — E2E 测试编写

**输入**：设计文档

**输出**：可运行代码 + 测试

<HARD-GATE>
**阻断条件**：编译/测试不通过不进入 Doc-Sync

**检查项**：
- [ ] 代码已编写
- [ ] 单元测试已编写并通过
- [ ] 集成测试已编写并通过
- [ ] E2E 测试已编写并通过（如需要）
- [ ] 编译通过
</HARD-GATE>

**流程**：
1. 使用 writing-plans 编写实施计划
2. 使用 test-strategy 制定测试计划
3. 使用 TDD 进行开发（红-绿-重构，垂直切片）
4. 编写单元测试和集成测试
5. 编写 E2E 测试（如需要）
6. 确保所有测试通过

**Anti-Patterns**：
- ✗ 先写代码再补测试
- ✗ 只测 happy path，不测边界情况
- ✗ 测试依赖实现细节，而不是行为
- ✗ 一次写完所有测试再写实现（水平切片）

---

### 阶段 4：Doc-Sync（文档同步）

**目标**：同步更新所有相关文档

**使用的 Skill**：
- `docs/sync.md` — 文档同步
- `docs/validate.md` — 文档一致性校验

**输入**：代码变更 diff

**输出**：更新后的文档

<HARD-GATE>
**阻断条件**：文档未同步不进入 Verify

**检查项**：
- [ ] 变更范围已识别
- [ ] 受影响文档已更新
- [ ] 文档一致性校验通过
</HARD-GATE>

**流程**：
1. 使用 doc-sync 同步文档
2. 使用 doc-validate 校验一致性
3. 修复所有不一致问题

**Anti-Patterns**：
- ✗ "代码写完了，文档以后再补"
- ✗ 只更新代码注释，不更新外部文档
- ✗ 文档更新后不校验一致性

---

### 阶段 5：Verify（验证）

**目标**：从用户视角验证功能是否真正实现

**使用的 Skill**：
- `testing/verify.md` — 用户视角功能验证

**输入**：功能代码 + 文档

**输出**：验证报告

<HARD-GATE>
**阻断条件**：用户视角验证不通过不进入 Release

**检查项**：
- [ ] 用户验收条件已列出
- [ ] E2E 测试已执行
- [ ] 手动验证已完成（如需要）
- [ ] 验证报告已输出
- [ ] 所有验收条件满足
</HARD-GATE>

**流程**：
1. 列出用户验收条件
2. 执行 E2E 测试
3. 手动验证（如需要）
4. 输出验证报告
5. 修复发现的问题（可回退到 Implement）

**Anti-Patterns**：
- ✗ "编译通过就算完成了"
- ✗ 只测功能，不测用户体验
- ✗ 跳过手动验证
- ✗ 验收条件模糊，无法验证

---

### 阶段 6：Release（发布）

**目标**：发布部署

**使用的 Skill**：
- `release/deploy.md` — 发布部署流程

**输入**：验证通过的代码

**输出**：发布产物

<HARD-GATE>
**阻断条件**：发布前必须确认

**检查项**：
- [ ] 版本号已确定
- [ ] Docker 镜像已构建并测试
- [ ] 镜像已推送到镜像仓库
- [ ] CHANGELOG 已更新
- [ ] Git tag 已创建
- [ ] GitHub Release 已创建
</HARD-GATE>

**流程**：
1. 确定版本号
2. 构建 Docker 镜像
3. 推送到镜像仓库
4. 更新 CHANGELOG
5. 创建 Git tag + GitHub Release

**Anti-Patterns**：
- ✗ 不更新 CHANGELOG
- ✗ 版号不遵循语义化版本
- ✗ 发布后不验证

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

**Anti-Patterns**：
- ✗ 跳过回顾，直接开始下一个需求
- ✗ 只记录问题，不分析根因
- ✗ 分析完不更新 skill

---

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
- `CONTEXT.md` — 领域知识
- 各阶段对应的 skill 文件
