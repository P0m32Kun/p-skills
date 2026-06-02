---
name: tdd
description: 测试驱动开发，红-绿-重构循环，先写测试再写实现
version: 1.0.0
tags: [testing, tdd, development]
triggers:
  - "TDD"
  - "测试驱动"
  - "红绿重构"
  - "test-driven"
inputs:
  - name: behaviors
    description: 需要测试的行为列表
    required: true
outputs:
  - name: tested_code
    description: 通过测试的实现代码
---

# 测试驱动开发

> **核心理念**：测试验证行为，不是实现。代码可以完全重构，测试不应该变。

## 前置条件
- 实施计划已编写（`workflow/writing-plans.md` 完成）
- 明确了要测试的行为列表

## 核心原则

1. **测试行为，不测实现** — 测试应该描述系统"做什么"，不是"怎么做"
2. **垂直切片** — 一个测试 → 一个实现 → 重复，不要水平切片
3. **最小实现** — 只写刚好让当前测试通过的代码
4. **绝不重构红灯** — 测试失败时不能重构，先变绿

## 流程

### 1. 规划测试行为

在写代码之前，确认：

- [ ] 与用户确认需要哪些公共接口变更
- [ ] 与用户确认哪些行为需要测试（按优先级排序）
- [ ] 列出要测试的行为（不是实现步骤）
- [ ] 获得用户对测试计划的批准

**问用户**："公共接口应该长什么样？哪些行为最重要需要测试？"

**不可能测所有东西。** 与用户确认哪些行为最关键，聚焦测试精力在核心路径和复杂逻辑上。

### 2. 垂直切片：一个测试一个实现

```
红灯：写第一个行为的测试 → 测试失败
绿灯：写最小代码让测试通过 → 测试通过
```

这是你的"示踪子弹"——证明端到端路径可行。

### 3. 逐个推进

对每个剩余行为，重复：

```
红灯：写下个测试 → 失败
绿灯：最小代码让测试通过 → 通过
```

**规则**：
- 一次只写一个测试
- 只写刚好通过当前测试的代码
- 不要预判未来的测试
- 测试聚焦可观测行为

### 4. 重构

所有测试通过后，寻找重构机会：

- [ ] 提取重复代码
- [ ] 深化模块（将复杂度隐藏在简单接口后面）
- [ ] 在自然的地方应用 SOLID 原则
- [ ] 思考新代码揭示了哪些现有代码的问题
- [ ] 每次重构后运行测试

**绝不在红灯时重构。** 先变绿。

## 每个循环的检查清单

```
[ ] 测试描述行为，不描述实现
[ ] 测试只使用公共接口
[ ] 测试能在内部重构后存活
[ ] 代码对当前测试来说是最小的
[ ] 没有添加投机性的功能
```

## 好测试 vs 坏测试

### 好测试：集成风格

通过公共接口测试真实代码路径：

```python
# ✓ 测试可观测行为
def test_user_can_checkout_with_valid_cart():
    cart = create_cart()
    cart.add(product)
    result = checkout(cart, payment_method)
    assert result.status == "confirmed"
```

**特征**：
- 测试用户/调用者关心的行为
- 只使用公共 API
- 能在内部重构后存活
- 描述"做什么"，不描述"怎么做"
- 每个测试一个逻辑断言

### 坏测试：耦合实现

依赖内部结构：

```python
# ✗ 测试实现细节
def test_checkout_calls_payment_service():
    mock_payment = mock(PaymentService)
    checkout(cart, payment)
    assert mock_payment.process.was_called_with(cart.total)
```

**危险信号**：
- Mock 内部协作者
- 测试私有方法
- 断言调用次数/顺序
- 重构时测试失败但行为没变
- 测试名描述"怎么做"而不是"做什么"

```python
# ✗ 绕过接口验证
def test_create_user_saves_to_db():
    create_user({"name": "Alice"})
    row = db.query("SELECT * FROM users WHERE name = 'Alice'")
    assert row is not None

# ✓ 通过接口验证
def test_create_user_makes_user_retrievable():
    user = create_user({"name": "Alice"})
    retrieved = get_user(user.id)
    assert retrieved.name == "Alice"
```

## Mock 指南

### 只在系统边界 Mock

**可以 Mock**：
- 外部 API（支付、邮件等）
- 数据库（有时——优先用测试数据库）
- 时间/随机数
- 文件系统（有时）

**不要 Mock**：
- 自己的类/模块
- 内部协作者
- 任何你能控制的东西

### 依赖注入

把外部依赖传入，而不是在内部创建：

```python
# ✓ 易于 Mock
def process_payment(order, payment_client):
    return payment_client.charge(order.total)

# ✗ 难以 Mock
def process_payment(order):
    client = StripeClient(os.environ["STRIPE_KEY"])
    return client.charge(order.total)
```

## Anti-Patterns

- ✗ **水平切片**：先写所有测试，再写所有实现
  - 批量写的测试测的是想象的行为，不是实际行为
  - 测试会测数据结构的"形状"而不是用户行为
  - 测试对真实变更不敏感：行为坏了通过，行为没变却失败
- ✗ 先写代码再补测试 — 失去 TDD 的反馈循环
- ✗ Mock 所有依赖 — 应该测试真实代码路径
- ✗ 只测 happy path — 边界情况更重要
- ✗ 测试依赖实现细节 — 重构时测试会无故失败
- ✗ 测试名描述"怎么做" — 应该描述"做什么"
- ✗ 红灯时重构 — 先变绿再重构

## 完成标准
- [ ] 测试行为列表已确认
- [ ] 每个行为有对应的测试
- [ ] 所有测试通过
- [ ] 测试使用公共接口，不耦合实现
- [ ] 代码是最小实现，无投机性功能
- [ ] 重构已完成（如需要）
- [ ] 所有测试仍然通过

## 参考
- `testing/strategy.md` — 测试策略选择
- `testing/e2e-write.md` — E2E 测试编写
- `testing/verify.md` — 用户视角功能验证
- `workflow/writing-plans.md` — 实施计划
- [mattpocock/skills TDD](https://github.com/mattpocock/skills) — 设计来源
- [Superpowers TDD](https://github.com/obra/superpowers) — 设计来源
