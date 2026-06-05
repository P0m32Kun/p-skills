---
name: test-strategy
description: >
  Use when choosing test strategy, deciding test levels, or planning test
  approach. Use when user says "测试策略", "选择测试层级", "test strategy",
  "what to test", "测试方案", "怎么测", "避免假实现".
---

# 测试策略选择

## Overview

根据变更类型和风险等级，通过决策树选择合适的测试层级（Unit / Integration / E2E）。风险驱动，成本效益平衡。

## When to Use

- 选择测试策略、决定测试层级
- 规划测试方法
- 用户说"测试策略"、"选择测试层级"

**何时不用**：
- 已经确定要写测试，需要具体编写 → 用 `tdd` 或 `e2e-write`
- 只需要验证功能 → 用 `verify`

> 根据变更类型选择合适的测试策略和层级。本 skill 是 **Implement 阶段**的选层工具；验收信号来自 `openspec`，场景来自 `bdd`，由 `develop-feature` 编排。

## 方法论栈（不重复造轮子）

| 层 | Skill | 回答的问题 |
|----|-------|-----------|
| SDD | `openspec` | 构建什么？验收信号是什么？ |
| BDD | `bdd` | 用户可观察的行为是什么？ |
| TDD | `tdd` | 这段逻辑如何保证正确？ |
| 选层 | **本 skill** | 这次改动写哪层测试？ |
| E2E | `e2e-write` | 用户路径如何从浏览器验收？ |
| 收口 | `verify` | 真实环境下是否真能用？ |

## 变更类型 → 需要哪些层

| 变更类型 | SDD | BDD 场景 | TDD | E2E |
|----------|-----|----------|-----|-----|
| 新功能 / 新 API / 新 UI | 是 | 是 | 是 | 用户路径是 |
| 用户可见 bug | 简版 | 回归场景 | 先 failing test | 视影响 |
| 纯重构（行为不变） | 否 | 沿用现有 | 保测试绿 | 否 |
| 文案 / typo | 否 | 否 | 否 | 否 |

## 前置条件

- 需求已完成设计（或 openspec spec 已存在）
- 明确变更类型和范围

## 核心原则

1. **风险驱动** — 高风险区域多测试
2. **成本效益** — 测试成本与收益平衡
3. **反馈速度** — 优先快速反馈的测试

## 流程

### 1. 分析变更类型

| 变更类型 | 示例 | 风险等级 |
|---------|------|---------|
| 新功能 | 添加用户注册 | 高 |
| Bug 修复 | 修复登录错误 | 中-高 |
| 重构 | 优化代码结构 | 中 |
| 配置变更 | 修改环境变量 | 低 |
| 文档更新 | 更新 README | 低 |

### 2. 决策树：选择测试层级

```
变更影响用户界面？
├── 是 → E2E 测试 + 集成测试
└── 否 → 变更涉及多个模块协作？
    ├── 是 → 集成测试 + 单元测试
    └── 否 → 变更逻辑复杂？
        ├── 是 → 单元测试
        └── 否 → 手动验证
```

### 3. 测试层级详解

#### Unit 测试

**适用场景**：
- 纯函数逻辑
- 复杂算法
- 边界条件

**示例**：
```typescript
describe('calculateDiscount', () => {
  it('满 100 减 10', () => {
    expect(calculateDiscount(100)).toBe(90);
  });

  it('不满 100 不减', () => {
    expect(calculateDiscount(50)).toBe(50);
  });
});
```

#### Integration 测试

**适用场景**：
- 模块间交互
- API 接口
- 数据库操作

**示例**：
```typescript
describe('用户注册 API', () => {
  it('注册成功返回用户信息', async () => {
    const response = await request(app)
      .post('/api/register')
      .send({ username: 'test', password: '123456' });

    expect(response.status).toBe(201);
    expect(response.body.user.username).toBe('test');
  });
});
```

#### E2E 测试

**适用场景**：
- 关键用户流程
- 跨页面交互
- 完整业务场景

**示例**：
```typescript
test('用户注册并登录', async ({ page }) => {
  await page.goto('/register');
  await page.fill('#username', 'testuser');
  await page.fill('#password', '123456');
  await page.click('#submit');

  await expect(page).toHaveURL('/login');
  await page.fill('#username', 'testuser');
  await page.fill('#password', '123456');
  await page.click('#login');

  await expect(page.locator('.welcome')).toContainText('testuser');
});
```

### 4. 输出测试计划

```markdown
## 测试计划

### 变更概述
- **类型**：[新功能/Bug 修复/重构]
- **影响范围**：[模块/功能]
- **风险等级**：[高/中/低]

### 测试策略
- **Unit 测试**：[需要/不需要] — [覆盖范围]
- **Integration 测试**：[需要/不需要] — [覆盖范围]
- **E2E 测试**：[需要/不需要] — [覆盖范围]

### 测试用例
1. [测试用例 1]
2. [测试用例 2]
3. [测试用例 3]

### 测试数据
- [测试数据需求]

### 环境要求
- [环境要求]
```

## Anti-Patterns

- ✗ 所有变更都写 E2E 测试
- ✗ 只写单元测试，不测试集成
- ✗ 不考虑风险等级，平均分配测试
- ✗ 测试计划不清晰

## 完成标准

- [ ] 变更类型已明确
- [ ] 决策树已应用
- [ ] 测试层级已选择
- [ ] 测试计划已输出

## Red Flags — STOP

当你有以下任何想法时，**停下来重新检查**：

- "全写单元测试就行"
- "E2E 覆盖所有场景"
- "不写测试策略"
- "凭感觉选"
- "测试覆盖率 100% 就行"

**所有这些都意味着你正在合理化跳过流程。回到 test-strategy 的第一步。**

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "单元测试覆盖够了" | 单元测试不验证集成和用户流程 |
| "全用 E2E" | E2E 慢、脆、贵 |
| "凭经验选" | 经验可能不适用于当前变更 |
| "测试策略文档太重" | 几句话就行，关键是显式决策 |
| "覆盖率 100% 就好" | 覆盖率 ≠ 测试质量 |

## 三道闸（防「代码写了、功能没实现」）

| 闸 | 规则 |
|----|------|
| Spec 闸 | 无验收信号（REQ-x）不写实现 |
| 行为闸 | 测试描述可观察行为，非实现细节；E2E 禁止在 test body 用 API 断言业务结果 |
| 实现闸 | 核心逻辑先有 failing test，再写代码 |

## 参考

- `skills/develop-feature/` — 全流程编排
- `skills/openspec/`、`skills/bdd/` — 验收与场景
- `skills/tdd/` — 测试驱动开发
- `skills/e2e-write/` — E2E 测试编写
- `skills/verify/` — 真实环境验收
- [Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) — 测试金字塔
