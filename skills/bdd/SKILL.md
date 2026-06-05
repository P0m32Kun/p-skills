---
name: bdd
description: >
  Use when writing behavior-driven tests, Gherkin feature files, or
  conducting discovery workshops. Use when user says "BDD", "行为驱动",
  "Gherkin", "feature file", "Three Amigos", "Example Mapping", "验收标准",
  "scenario", "Given-When-Then", "specification by example".
---

# 行为驱动开发

> 通过自然语言描述系统行为，让产品、开发和测试三方基于具体示例达成共识。

## Overview

BDD（行为驱动开发）是一种敏捷软件开发方法，通过结构化的协作方式（Discovery → Formulation → Automation），让业务、开发和测试三方基于具体示例达成共识，确保交付的功能与用户预期完全一致。

## When to Use

**触发场景**：
- 编写 Gherkin Feature 文件
- 组织 Discovery Workshop / Example Mapping
- 需要将业务需求转化为可执行规范
- 为新功能定义验收标准
- 团队对需求理解存在分歧，需要通过示例澄清

**何时不用**：
- 需求非常明确且简单，无需多方对齐
- 纯技术性任务（重构、性能优化）
- 项目时间极其紧迫，无法投入前期 Discovery
- 团队只有一个人，没有 Three Amigos 协作条件

## 前置条件

- 需求或功能已初步明确
- 了解项目技术栈和可用的 BDD 工具

## 核心原则

1. **对话优先** — BDD 的本质不是工具，而是结构化的协作对话
2. **示例驱动** — 用具体示例澄清需求，而非抽象描述
3. **活文档** — Feature 文件既是规范也是测试，持续维护
4. **声明式** — 描述"做什么"，不描述"怎么做"

## BDD 在 p-skills 中的位置

与 `openspec` / `tdd` 嵌套（见 `develop-feature`）：

```
SDD（openspec）：构建什么 + REQ-x 验收信号
  └── BDD（本 skill）：可观察行为 + 场景 ID
        └── TDD：红-绿-重构实现
```

## BDD 与 TDD 的关系

两者**互补而非互斥** — BDD 定行为，TDD 定实现；Automation 阶段内部走 TDD。

| 维度 | TDD | BDD |
|------|-----|-----|
| 关注点 | 代码正确性 | 系统行为 |
| 驱动力 | 开发者 | Three Amigos |
| 语言 | 编程语言 | 自然语言（Gherkin） |
| 粒度 | 函数/方法 | 用户故事/业务场景 |
| 受众 | 开发者 | 全团队 |

在 p-skills 中的衔接：BDD 的 Automation 阶段内部使用 TDD 红绿重构来驱动实现。

## 流程

### Phase 1: Discovery Workshop（25-30 分钟/Story）

**参与者**：产品负责人 + 开发者 + 测试者（Three Amigos）

**Example Mapping 方法**：
- 黄色卡片：User Story
- 蓝色卡片：业务规则/验收标准
- 绿色卡片：具体示例
- 红色卡片：待澄清问题

**产出**：
- 共同理解
- 示例清单
- 问题清单

### Phase 2: Formulation（编写 Feature 文件）

将示例转化为 Gherkin 格式：

```gherkin
Feature: 用户登录
  作为一个注册用户
  我希望能够登录系统
  以便访问我的个人资料

  Scenario: 正确用户名密码登录成功
    Given 用户已注册，用户名为 "admin"，密码为 "password123"
    When 用户使用用户名 "admin" 和密码 "password123" 登录
    Then 登录成功
    And 跳转到个人资料页面

  Scenario: 错误密码登录失败
    Given 用户已注册，用户名为 "admin"，密码为 "password123"
    When 用户使用用户名 "admin" 和密码 "wrong" 登录
    Then 登录失败
    And 显示错误信息 "用户名或密码错误"
```

**编写规范**：
- 声明式，避免命令式（✅ `Given 用户已登录` ❌ `Given 输入用户名密码，点击登录按钮`）
- 每个场景 3-5 步
- 使用领域语言，避免技术术语
- 保持一致性
- 团队审查确认

### Phase 2.5: 轻量落地（无 Cucumber 时）

许多项目用 **Markdown 场景表 + Playwright/Jest** 即可，不必上 Gherkin 框架：

1. 在项目验收文档维护「场景注册表」（列：场景 ID、GWT 摘要、自动化 spec 路径、状态）
2. E2E spec 文件头引用场景 ID（如 `E2E-FLOW-01`）
3. PR 改相关功能时同步更新场景表

场景 ID 建议：`FT-<域>-<序号>`（手工）、`E2E-<域>-<序号>`（自动化）。

### Phase 3: Automation（编写 Step Definitions）

选择合适的工具：

| 工具 | 语言 | 适用场景 |
|------|------|---------|
| Cucumber.js | JavaScript/TS | Node.js 项目 |
| Cucumber-JVM | Java/Kotlin | 企业级 Java |
| SpecFlow | C#/.NET | .NET 项目 |
| Behave | Python | Python 项目 |
| playwright-bdd | JavaScript/TS | 浏览器自动化 + BDD |

**实现步骤**：
1. 编写 Step Definitions 连接规范到系统
2. 内部可使用 TDD 红绿重构驱动实现
3. 运行测试，确保通过

## 完成标准

- [ ] Discovery Workshop 已举行，Three Amigos 达成共识
- [ ] Feature 文件已编写，覆盖 Happy Path 和关键边界
- [ ] Feature 文件通过团队审查
- [ ] Step Definitions 已编写并连接到系统
- [ ] 所有场景测试通过
- [ ] Feature 文件作为活文档纳入版本控制

## Red Flags — STOP

当你有以下任何想法时，**停下来重新检查**：

- "跳过 Discovery 直接写 Feature"
- "开发者独自编写 Feature"
- "Feature 文件包含 UI 实现细节"
- "场景超过 10 步"
- "只为 Happy Path 写场景"
- "BDD 太慢，直接写代码更快"
- "Gherkin 格式太死板"

**所有这些都意味着你正在合理化跳过流程。BDD 的价值在于对话，不在于格式。**

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "跳过 Discovery 直接写" | Discovery 是 BDD 的核心，跳过它只是换了格式的 TDD |
| "开发者独自写 Feature" | 独自写 = 你的理解，不是团队共识 |
| "太慢了" | 前期慢 1 小时，后期省 10 小时返工 |
| "Gherkin 太死板" | 格式是工具，共识是目的 |
| "直接写代码更快" | 快但错 = 最慢 |
| "BDD 只适合大项目" | 小项目更需要清晰的需求边界 |

## 参考

- [Introducing BDD — Dan North](https://dannorth.net/introducing-bdd/) — BDD 原始定义
- [Discovery: Explore Requirements Using Example Mapping](https://cucumber.io/blog/bdd/example-mapping-introduction/) — Example Mapping 方法
- [The Cucumber Book](https://pragprog.com/titles/hwcuc2/the-cucumber-book-second-edition/) — BDD 实践指南
- [playwright-bdd](https://github.com/vitalets/playwright-bdd) — Playwright + BDD 集成
