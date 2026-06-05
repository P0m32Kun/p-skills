---
name: writing-plans
description: >
  Use when writing implementation plans, breaking down tasks, or creating
  step-by-step execution plans. Use when user says "编写实施计划", "拆解任务",
  "writing plans", "implementation plan".
---

# 实施计划编写

## Overview

将设计文档拆解为可执行的实施计划。每个任务都是原子操作（2-30 分钟），可验证、可中断、无占位符。

## When to Use

- 编写实施计划、拆解任务
- 将设计文档转化为可执行步骤
- 用户说"编写实施计划"、"拆解任务"、"writing plans"

**何时不用**：
- 设计还没完成（先跑 `brainstorming`）
- 只需要修 bug → 用 `fix-bug`
- 任务很简单，不需要计划

> 将设计文档拆解为可执行的实施计划，每步都是原子操作。

## 前置条件

- 设计文档已批准（brainstorming 阶段完成）
- 技术方案已确定

## 核心原则

1. **原子任务** — 每个任务只做一件事
2. **可验证** — 每个任务都有明确的完成标准
3. **可中断** — 任务之间相互独立，可以随时暂停
4. **无占位符** — 所有代码都是完整的，不留 TODO

## 流程

### 1. 确认范围

- 阅读设计文档
- 确认实施范围
- 识别依赖关系

### 2. 规划文件结构

列出需要创建或修改的文件：

```markdown
## 文件变更

### 新增文件
- `src/feature/new-module.ts` — 新模块实现
- `src/feature/new-module.test.ts` — 测试文件

### 修改文件
- `src/index.ts` — 添加新模块导出
- `package.json` — 添加新依赖
```

### 3. 编写计划文档

```markdown
# [功能名称] 实施计划

## 概述
- 目标：...
- 预计时间：...
- 依赖：...

## 任务列表

### Task 1: [任务名称]
- **目标**：...
- **文件**：...
- **步骤**：
  1. ...
  2. ...
- **验证**：...
- **状态**：pending

### Task 2: [任务名称]
...
```

### 4. 禁止占位符

**每个任务的代码必须完整**，不能有：

```markdown
# 错误示例
- 实现用户认证功能（具体实现待定）
- 添加数据库操作（代码略）

# 正确示例
- 实现用户认证功能
  ```typescript
  async function authenticate(username: string, password: string): Promise<User> {
    const user = await db.users.findByUsername(username);
    if (!user || !await bcrypt.compare(password, user.passwordHash)) {
      throw new AuthenticationError('Invalid credentials');
    }
    return user;
  }
  ```
```

### 5. 计划自检

- [ ] 每个任务是否原子？
- [ ] 每个任务是否可验证？
- [ ] 任务之间是否独立？
- [ ] 是否有占位符或 TODO？
- [ ] 文件路径是否正确？
- [ ] 代码是否完整？

### 6. 保存计划

将计划保存到项目适当位置，通常在 `.plans/` 或 `docs/plans/` 目录下。

## 任务粒度指南

| 粒度 | 示例 | 适用场景 |
|------|------|---------|
| 2-5 分钟 | 创建文件、添加函数 | 简单变更 |
| 5-15 分钟 | 实现一个方法、编写测试 | 常规任务 |
| 15-30 分钟 | 实现一个模块 | 复杂任务 |
| > 30 分钟 | 需要拆分 | 太大了 |

## Anti-Patterns

- ✗ 任务太大，一个任务做多件事
- ✗ 任务之间有强依赖，不能独立执行
- ✗ 使用占位符或 TODO
- ✗ 不写验证步骤
- ✗ 文件路径不准确

## 完成标准

- [ ] 所有任务已列出
- [ ] 每个任务都是原子的
- [ ] 每个任务都有验证步骤
- [ ] 没有占位符或 TODO
- [ ] 计划已保存

## Red Flags — STOP

当你有以下任何想法时，**停下来重新检查**：

- "心里有数就行"
- "计划太细会僵化"
- "直接开干"
- "写个 TODO 列表就行"
- "用户没要求写计划"

**所有这些都意味着你正在合理化跳过流程。回到 writing-plans 的第一步。**

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "计划太细浪费时间" | 细到可执行才叫计划，否则是愿望 |
| "我脑子里有" | 你脑子里的没法给 subagent 执行 |
| "计划赶不上变化" | 计划可以改，但要先有 |
| "小任务不用计划" | 小任务也可能翻车 |
| "直接开始更快" | 开始快，迷路的成本更高 |

## 参考

- `skills/brainstorming/` — 前置：需求讨论
- `skills/develop-feature/` — 编排器：完整开发流程
- [The Pragmatic Programmer](https://www.amazon.co.uk/Pragmatic-Programmer-Anniversary-Journey-Mastery/dp/B0833F1T3V) — 小步前进
