---
name: e2e-write
description: >
  Use when writing E2E tests, end-to-end tests, or browser automation tests.
  Use when user says "编写 E2E 测试", "e2e test", "end-to-end test",
  "Playwright test".
---

# E2E 测试编写

## Overview

编写端到端测试，从用户视角验证完整业务流程。优先覆盖关键路径，避免 flaky test。

## When to Use

- 需要编写 E2E 测试、端到端测试、浏览器自动化测试
- 验证完整用户流程（跨页面、跨模块）
- 用户说"编写 E2E 测试"、"Playwright test"

**何时不用**：
- 只需要单元测试或集成测试 → 用 `tdd`
- 只需要选择测试策略 → 用 `test-strategy`
- 只需要验证功能 → 用 `verify`

> 编写端到端测试，验证完整的用户流程。

## 前置条件

- 需求已明确
- 项目已配置 E2E 测试框架（Playwright、Cypress 等）

## 核心原则

1. **用户视角** — 测试模拟真实用户操作
2. **独立性** — 每个测试相互独立
3. **可读性** — 测试代码清晰易懂
4. **稳定性** — 避免 flaky test

## 流程

### 1. 阅读项目 E2E 测试约定

先查项目是否有 `docs/conventions/testing.md` 或同类约定；通用硬性规则：

- **UI 断言业务结果** — `test()` body 内禁止用 `fetch` / `page.request` 断言「扫到了什么、保存了什么」
- **API 仅用于** setup / teardown / 长异步任务进度轮询（例外须在文件头说明原因）
- **文件头注释** — 标明测试层级、UI 断言点、API 用途、关联 BDD 场景 ID

```bash
# 查看现有测试结构
find . -name "*.spec.ts" -o -name "*.test.ts" | head -20

# 查看测试配置
cat playwright.config.ts
```

### 2. 编写 spec

#### 文件头注释

```typescript
/**
 * E2E 测试：用户登录
 *
 * 测试场景：
 * - 正常登录流程
 * - 错误密码处理
 * - 用户不存在处理
 *
 * 前置条件：
 * - 测试用户已创建
 * - 应用已启动
 */
```

#### 测试结构

```typescript
import { test, expect } from '@playwright/test';

test.describe('用户登录', () => {
  test.beforeEach(async ({ page }) => {
    // 每个测试前的操作
    await page.goto('/login');
  });

  test('正常登录流程', async ({ page }) => {
    // Arrange: 准备测试数据
    const username = 'testuser';
    const password = '123456';

    // Act: 执行操作
    await page.fill('#username', username);
    await page.fill('#password', password);
    await page.click('#login-button');

    // Assert: 验证结果
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('.welcome')).toContainText(username);
  });

  test('错误密码显示错误提示', async ({ page }) => {
    // Arrange
    const username = 'testuser';
    const wrongPassword = 'wrongpassword';

    // Act
    await page.fill('#username', username);
    await page.fill('#password', wrongPassword);
    await page.click('#login-button');

    // Assert
    await expect(page.locator('.error-message')).toContainText('密码错误');
    await expect(page).toHaveURL('/login');
  });

  test('用户不存在显示错误提示', async ({ page }) => {
    // Arrange
    const nonExistentUser = 'nonexistentuser';
    const password = '123456';

    // Act
    await page.fill('#username', nonExistentUser);
    await page.fill('#password', password);
    await page.click('#login-button');

    // Assert
    await expect(page.locator('.error-message')).toContainText('用户不存在');
  });
});
```

### 3. 覆盖状态

确保测试覆盖各种状态：

| 状态 | 测试场景 |
|------|---------|
| 正常流程 | 用户输入正确信息 |
| 边界情况 | 空输入、超长输入、特殊字符 |
| 错误处理 | 网络错误、服务器错误 |
| 权限控制 | 未登录、权限不足 |

### 4. Docker 环境运行验证

```bash
# 在 Docker 中运行测试
docker run --rm \
  -v $(pwd):/app \
  -w /app \
  mcr.microsoft.com/playwright:v1.40.0-focal \
  npx playwright test

# 查看测试报告
npx playwright show-report
```

## 完成标准

- [ ] 测试覆盖主要用户流程
- [ ] 测试覆盖边界情况
- [ ] 测试在 Docker 环境通过
- [ ] 测试代码清晰易懂
- [ ] 没有 flaky test

## Red Flags — STOP

当你有以下任何想法时，**停下来重新检查**：

- "单元测试够了"
- "E2E 太慢"
- "先手动测一下"
- "mock 一下就行"
- "flaky 没关系"

**所有这些都意味着你正在合理化跳过流程。回到 e2e-write 的第一步。**

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "单元测试覆盖够了" | 单元测试不验证用户流程 |
| "E2E 太慢太脆" | 慢和脆是设计问题，不是 E2E 的问题 |
| "mock 外部服务就行" | mock 不验证真实集成 |
| "先手动测一下" | 手动测不能回归 |
| "flaky 之后再修" | Flaky test 比没 test 更糟（没人信） |

## 参考

- `skills/test-strategy/` — 测试策略选择
- [Playwright 官方文档](https://playwright.dev/) — E2E 测试框架
- [Cypress 官方文档](https://docs.cypress.io/) — E2E 测试框架
