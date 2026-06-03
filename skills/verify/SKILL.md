---
name: verify
description: >
  Use when verifying features from user perspective, running acceptance tests,
  or validating user requirements. Use when user says "用户验证", "验收测试",
  "verify", "acceptance test".
---

# 用户视角功能验证

> 从用户角度验证功能是否满足需求。

## 前置条件

- 功能已实现
- 单元测试和集成测试已通过

## 核心原则

1. **用户视角** — 站在用户角度思考
2. **SMART 验收条件** — 具体、可衡量、可达成、相关、有时限
3. **边界情况** — 测试正常流程和异常流程

## 流程

### 1. 列出用户验收条件

基于需求，列出用户验收条件：

```markdown
## 用户验收条件

### 用户登录
- [ ] 正确用户名密码 → 登录成功，跳转首页
- [ ] 错误密码 → 显示错误提示，不跳转
- [ ] 用户不存在 → 显示错误提示，不跳转
- [ ] 密码为空 → 显示错误提示，不跳转
- [ ] 用户名为空 → 显示错误提示，不跳转

### 边界情况
- [ ] 密码包含特殊字符 → 正常处理
- [ ] 用户名包含中文 → 正常处理
- [ ] 网络超时 → 显示超时提示
```

### 2. 执行验证

#### 自动化验证（E2E 测试）

```typescript
test('用户登录验证', async ({ page }) => {
  // 正常流程
  await page.goto('/login');
  await page.fill('#username', 'admin');
  await page.fill('#password', '123456');
  await page.click('#login');
  await expect(page).toHaveURL('/dashboard');

  // 错误密码
  await page.goto('/login');
  await page.fill('#username', 'admin');
  await page.fill('#password', 'wrong');
  await page.click('#login');
  await expect(page.locator('.error')).toContainText('密码错误');
});
```

#### 手动验证

按照验收条件手动验证：

1. 打开应用
2. 按照复现步骤操作
3. 观察实际结果
4. 对比期望结果
5. 记录结果

### 3. 输出验证报告

```markdown
## 验证报告

### 验证时间
[YYYY-MM-DD HH:MM]

### 验证结果
- **自动化测试**：✅ 通过 (X/X)
- **手动验证**：✅ 通过

### 验收条件检查
- [ ] 条件 1：✅ 通过
- [ ] 条件 2：✅ 通过
- [ ] 条件 3：❌ 失败 — [原因]

### 发现的问题
- [问题 1 描述]
- [问题 2 描述]

### 建议
- [建议 1]
- [建议 2]
```

## Anti-Patterns

- ✗ 只验证正常流程，不验证异常流程
- ✗ 不列出验收条件，随意测试
- ✗ 只做手动验证，不写自动化测试
- ✗ 发现问题不记录

## 完成标准

- [ ] 所有用户验收条件已列出
- [ ] 自动化测试已编写并通过
- [ ] 手动验证已完成
- [ ] 验证报告已输出
- [ ] 发现的问题已记录

## 参考

- `testing/e2e-write.md` — E2E 测试编写
- `workflow/develop.feature.md` — 完整开发流程
- [Acceptance Testing](https://en.wikipedia.org/wiki/Acceptance_testing) — 验收测试
