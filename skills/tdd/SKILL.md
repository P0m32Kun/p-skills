---
name: tdd
description: >
  Use when implementing features or bugfixes using test-driven development.
  Use when user says "TDD", "测试驱动", "红绿重构", "test-driven",
  "test first", "先写测试".
---

# 测试驱动开发

> 红-绿-重构循环，先写测试再写实现。

## 前置条件

- 需求或 Bug 已明确
- 已了解项目的技术栈和测试框架

## 核心原则

1. **先写测试** — 测试是规格说明，不是事后补充
2. **最小实现** — 只写让测试通过的最少代码
3. **逐步重构** — 测试通过后再优化代码
4. **垂直切片** — 一个测试一个实现，不要横向扩展

## 流程

### 1. 规划测试行为

列出需要测试的行为：

```markdown
## 测试行为列表

### 用户登录
- [ ] 正确用户名密码 → 登录成功
- [ ] 错误密码 → 登录失败
- [ ] 用户不存在 → 登录失败
- [ ] 密码为空 → 登录失败
```

### 2. 垂直切片：一个测试一个实现

**不要横向扩展**（先写所有测试，再写所有实现）

```
❌ 错误方式：
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

✅ 正确方式：
  RED→GREEN: test1 → impl1
  RED→GREEN: test2 → impl2
  RED→GREEN: test3 → impl3
  ...
```

### 3. 逐个推进

对于每个测试行为：

#### RED：写一个失败的测试

```typescript
// 1. 写一个失败的测试
describe('用户登录', () => {
  it('正确用户名密码 → 登录成功', async () => {
    const result = await login('admin', 'password123');
    expect(result.success).toBe(true);
    expect(result.user.username).toBe('admin');
  });
});
```

```bash
# 2. 运行测试，确认失败
npm test -- --testPathPattern=login.test.ts
```

#### GREEN：写最少的代码让测试通过

```typescript
// 3. 写最少的代码让测试通过
async function login(username: string, password: string): Promise<LoginResult> {
  const user = await db.users.findByUsername(username);
  if (!user || user.password !== password) {
    return { success: false };
  }
  return { success: true, user };
}
```

```bash
# 4. 运行测试，确认通过
npm test -- --testPathPattern=login.test.ts
```

#### REFACTOR：优化代码

```typescript
// 5. 优化代码（测试仍然通过）
async function login(username: string, password: string): Promise<LoginResult> {
  const user = await db.users.findByUsername(username);
  if (!user || !await bcrypt.compare(password, user.passwordHash)) {
    return { success: false, error: 'Invalid credentials' };
  }
  return { success: true, user };
}
```

```bash
# 6. 运行测试，确认仍然通过
npm test -- --testPathPattern=login.test.ts
```

### 4. 重构

完成所有测试后，进行整体重构：
- 提取公共代码
- 优化命名
- 改善代码结构
- 运行所有测试确认没有破坏

## 每个循环的检查清单

- [ ] 测试是否描述了行为，而不是实现？
- [ ] 测试是否在修复前失败（RED）？
- [ ] 实现是否最小化（GREEN）？
- [ ] 重构后测试是否仍然通过？
- [ ] 测试名称是否清晰？

## 好测试 vs 坏测试

### 好测试：集成风格

测试通过公共接口验证行为：

```typescript
// 好：测试公共接口的行为
describe('购物车', () => {
  it('添加商品后数量增加', () => {
    const cart = new ShoppingCart();
    cart.add({ id: '1', name: '商品', price: 100 });
    expect(cart.items).toHaveLength(1);
    expect(cart.total).toBe(100);
  });
});
```

### 坏测试：耦合实现

测试内部实现细节：

```typescript
// 坏：测试内部实现
describe('购物车', () => {
  it('调用 addItem 方法', () => {
    const cart = new ShoppingCart();
    const spy = jest.spyOn(cart, 'addItem');
    cart.add({ id: '1', name: '商品', price: 100 });
    expect(spy).toHaveBeenCalled(); // 测试实现，不是行为
  });
});
```

## Mock 指南

### 只在系统边界 Mock

```typescript
// ✅ Mock 外部服务
jest.mock('./external-api', () => ({
  fetchUser: jest.fn().mockResolvedValue({ id: '1', name: 'Test User' }),
}));

// ✅ Mock 数据库
jest.mock('./database', () => ({
  users: {
    findByUsername: jest.fn().mockResolvedValue({ id: '1', username: 'admin' }),
  },
}));

// ❌ 不要 Mock 内部模块
jest.mock('./utils', () => ({
  calculateTotal: jest.fn(), // 这是内部实现，不应该 Mock
}));
```

### 依赖注入

使用依赖注入而不是直接 Mock：

```typescript
// ✅ 依赖注入
class UserService {
  constructor(private db: Database) {}

  async getUser(id: string): Promise<User> {
    return this.db.users.findById(id);
  }
}

// 测试时注入 Mock
const mockDb = { users: { findById: jest.fn() } };
const service = new UserService(mockDb as any);
```

## Anti-Patterns

- ✗ 先写实现再补测试
- ✗ 一次写完所有测试再写实现
- ✗ 测试内部实现而不是行为
- ✗ 过度 Mock，测试变成实现的镜像
- ✗ 测试不运行就提交
- ✗ 重构时不运行测试

## 完成标准

- [ ] 所有测试行为已覆盖
- [ ] 每个测试都经历过 RED-GREEN-REFACTOR 循环
- [ ] 测试描述行为，不描述实现
- [ ] Mock 只在系统边界
- [ ] 所有测试通过

## 参考

- [Kent Beck: Test-Driven Development](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530) — TDD 原著
- [Growing Object-Oriented Software](https://www.amazon.com/Growing-Object-Oriented-Software-Guided-Tests/dp/0321503627) — TDD 实践
- [mattpocock/skills](https://github.com/mattpocock/skills) — TDD skill 设计
- [obra/superpowers](https://github.com/obra/superpowers) — test-driven-development skill
