---
name: test-strategy
description: 根据变更类型选择测试策略
version: 1.1.0
tags: [testing, strategy, planning]
triggers:
  - "测试策略"
  - "测试计划"
  - "进入 Implement 前"
inputs:
  - name: change_type
    description: 变更类型（新增功能/修 bug/重构/配置变更）
    required: true
  - name: change_scope
    description: 变更范围
    required: true
outputs:
  - name: test_plan
    description: 测试计划
---

# 测试策略选择

## 前置条件
- 需求已完成设计（Design 阶段通过）
- 明确变更类型和范围

## 核心原则

1. **测试行为，不是实现** — 测试应该验证系统做什么，而不是怎么做
2. **垂直切片** — 一次一个测试 → 一次一个实现，不要水平切片
3. **优先级排序** — 先测核心路径，再测边界情况

## 流程

### 1. 分析变更类型

| 变更类型 | 描述 | 典型场景 |
|---------|------|---------|
| 新增功能 | 添加新的用户功能 | 新增 API、新增页面 |
| 修 bug | 修复已知问题 | 修复逻辑错误、修复样式 |
| 重构 | 不改变行为的代码优化 | 代码结构调整、性能优化 |
| 配置变更 | 修改配置或依赖 | 环境变量、依赖升级 |

### 2. 决策树：选择测试层级

```
变更类型？
├── 新增功能
│   ├── 核心功能（用户可见）→ Unit + Integration + E2E
│   ├── 辅助功能（内部）→ Unit + Integration
│   └── 配置/文档 → Integration
│
├── 修 bug
│   ├── 逻辑错误 → Unit + Integration
│   ├── 样式问题 → E2E
│   ├── 性能问题 → Unit + Benchmark
│   └── 安全漏洞 → Unit + Integration + E2E
│
├── 重构
│   ├── 有测试覆盖 → Unit（回归）+ Integration（回归）
│   └── 无测试覆盖 → 先补 Unit，再重构
│
└── 配置变更
    ├── 影响运行时 → Integration + E2E（回归）
    └── 不影响运行时 → 无需测试
```

### 3. 测试层级详解

#### Unit 测试
- **适用**：独立函数、工具方法、业务逻辑
- **工具**：Jest、Vitest、Go test、pytest
- **覆盖率**：核心逻辑 100%
- **原则**：
  - 测试行为，不测试实现
  - 不要 mock 内部依赖
  - 测试应该像规格说明

#### Integration 测试
- **适用**：模块间交互、API 接口、数据库操作
- **工具**：Supertest、httpexpect、pytest
- **覆盖率**：关键路径 100%
- **原则**：
  - 测试真实代码路径
  - 使用真实数据库（测试容器）
  - 测试错误处理

#### E2E 测试
- **适用**：用户完整流程、跨系统交互
- **工具**：Playwright、Cypress、Selenium
- **覆盖率**：核心用户流程
- **原则**：
  - 测试用户视角
  - 覆盖加载/空/错误态
  - 使用 data-testid 定位元素

### 4. 输出测试计划

```markdown
## 测试计划

### 变更概述
- 类型：新增功能
- 范围：用户认证模块
- 影响：登录、注册、权限

### 决策路径
变更类型：新增功能
影响范围：核心功能（用户可见）
测试层级：Unit + Integration + E2E

### 测试策略

#### Unit 测试
- [ ] `auth.service.test.ts` — 密码加密、token 生成
- [ ] `user.model.test.ts` — 用户模型验证

#### Integration 测试
- [ ] `auth.api.test.ts` — 登录接口、注册接口
- [ ] `auth.middleware.test.ts` — 认证中间件

#### E2E 测试
- [ ] `login.spec.ts` — 用户登录流程
- [ ] `register.spec.ts` — 用户注册流程

### 测试环境
- 本地：Docker Compose
- CI：GitHub Actions

### 预计时间
- Unit：2 小时
- Integration：3 小时
- E2E：4 小时
```

<HARD-GATE>
**阻断条件**：测试计划未输出不进入 Implement

**检查项**：
- [ ] 变更类型已明确
- [ ] 决策树已应用
- [ ] 测试层级已选择
- [ ] 测试计划已输出
- [ ] 测试计划已评审
</HARD-GATE>

## Anti-Patterns

- ✗ "先写代码再补测试" — 应该 TDD
- ✗ 一次写完所有测试再写实现（水平切片）— 应该垂直切片
- ✗ 只测 happy path，不测边界情况
- ✗ 测试依赖实现细节，而不是行为 — 重构时测试会失败
- ✗ Mock 所有依赖 — 应该测试真实代码路径
- ✗ 跳过测试计划 — 直接开始写测试会导致覆盖不足

## 完成标准
- [ ] 变更类型已明确
- [ ] 决策树已应用
- [ ] 测试层级已选择
- [ ] 测试计划已输出
- [ ] 测试计划已评审

## 参考
- `testing/e2e-write.md` — E2E 测试编写
- `testing/verify.md` — 用户视角功能验证
- `testing/tdd.md` — 测试驱动开发
- `CONTEXT.md` — 领域知识
- [mattpocock/skills](https://github.com/mattpocock/skills) — TDD 设计来源
