---
name: writing-plans
description: 将设计文档拆解为可执行的实施计划，每步都是原子操作
version: 1.0.0
tags: [workflow, planning, implementation]
triggers:
  - "编写实施计划"
  - "拆解任务"
  - "writing plans"
inputs:
  - name: design_doc
    description: 已批准的设计文档
    required: true
outputs:
  - name: implementation_plan
    description: 实施计划文档
---

# 实施计划编写

> 将设计文档拆解为具体的、可执行的实施步骤。假设执行者对项目一无所知。

## 前置条件
- 设计文档已通过用户批准（`workflow/brainstorming.md` 完成）

## 核心原则

1. **假设零上下文** — 执行计划的人可能不了解项目，一切都要写清楚
2. **原子步骤** — 每步是一个动作（2-5 分钟），不能合并多个操作
3. **无占位符** — 每步必须有完整内容，禁止"待定"、"后续补充"
4. **TDD 驱动** — 先写测试，再写实现
5. **频繁提交** — 每个功能点完成后提交

## 流程

### 1. 确认范围

如果设计覆盖多个独立子系统，建议拆分为多个计划，每个计划独立产出可运行的代码。

### 2. 规划文件结构

在定义任务之前，先明确文件清单：

| 操作 | 文件路径 | 职责 |
|------|---------|------|
| 新建 | `src/auth/service.go` | 认证业务逻辑 |
| 修改 | `src/router/main.go:45-60` | 添加认证路由 |
| 新建 | `tests/auth/service_test.go` | 认证逻辑测试 |

**设计原则**：
- 每个文件一个清晰职责
- 文件之间通过明确接口通信
- 相关文件放在一起
- 遵循项目现有结构

### 3. 编写计划文档

#### 文档头部

```markdown
# [功能名称] 实施计划

> 基于设计文档：docs/specs/YYYY-MM-DD-<topic>-design.md

**目标**：[一句话描述做什么]

**架构**：[2-3 句话描述方案]

**技术栈**：[关键技术/库]

---
```

#### 任务结构

每个任务是一个独立的功能单元：

```markdown
### 任务 N：[组件名称]

**文件**：
- 新建：`exact/path/to/file.go`
- 修改：`exact/path/to/existing.go:123-145`
- 测试：`tests/exact/path/to/file_test.go`

- [ ] **步骤 1：编写失败的测试**

​```go
func TestUserCreation(t *testing.T) {
    user, err := CreateUser("alice", "alice@example.com")
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.Name != "alice" {
        t.Errorf("expected name alice, got %s", user.Name)
    }
}
​```

- [ ] **步骤 2：运行测试确认失败**

运行：`go test ./tests/auth/ -run TestUserCreation -v`
预期：FAIL — 函数未定义

- [ ] **步骤 3：编写最小实现**

​```go
func CreateUser(name, email string) (*User, error) {
    return &User{Name: name, Email: email}, nil
}
​```

- [ ] **步骤 4：运行测试确认通过**

运行：`go test ./tests/auth/ -run TestUserCreation -v`
预期：PASS

- [ ] **步骤 5：提交**

​```bash
git add src/auth/service.go tests/auth/service_test.go
git commit -m "feat: add CreateUser function"
​```
```

### 4. 禁止占位符

以下写法是**计划失败**，必须避免：

| 禁止写法 | 应该写 |
|---------|--------|
| "待定"、"TODO" | 实际内容 |
| "添加适当的错误处理" | 具体的错误处理代码 |
| "编写上述功能的测试" | 实际的测试代码 |
| "类似任务 N" | 重复完整代码（执行者可能乱序阅读） |
| 只描述做什么，不展示代码 | 必须有代码块 |

### 5. 计划自检

写完计划后，自查：

- [ ] **设计覆盖**：设计文档的每个需求是否都有对应任务？
- [ ] **占位符扫描**：搜索"待定"、"TODO"、"类似"等关键词
- [ ] **一致性检查**：后面任务引用的函数名/类型名是否与前面定义一致？
- [ ] **路径检查**：文件路径是否准确？
- [ ] **可执行性**：每步是否可以直接照做？

发现问题直接修复。

### 6. 保存计划

保存到 `docs/plans/YYYY-MM-DD-<feature-name>.md`（路径可按项目约定调整）。

## 任务粒度指南

**正确的粒度**（每步 2-5 分钟）：
```
✓ 编写失败的测试 → 运行确认失败 → 编写实现 → 运行确认通过 → 提交
```

**错误的粒度**：
```
✗ "实现整个用户模块" — 太大，无法跟踪
✗ "打开文件" — 太小，浪费时间
```

## Anti-Patterns

- ✗ 先写所有实现再补测试 — 应该 TDD 逐个推进
- ✗ 任务之间有隐式依赖 — 每个任务应该独立可执行
- ✗ 用"类似任务 N"省略代码 — 执行者可能乱序阅读
- ✗ 只写"做什么"不写"怎么做" — 必须有完整代码
- ✗ 计划过于宏大 — 聚焦当前设计范围
- ✗ 忽略提交步骤 — 每个功能点都要提交

## 完成标准
- [ ] 文件结构已规划
- [ ] 每个任务有完整的文件路径和代码
- [ ] 无占位符（无"待定"、"TODO"、"类似"）
- [ ] 每步都是原子操作（2-5 分钟）
- [ ] TDD 流程：先测试后实现
- [ ] 计划自检通过
- [ ] 计划文档已保存

## 参考
- `workflow/brainstorming.md` — 设计阶段（前置步骤）
- `testing/tdd.md` — TDD 开发流程
- `workflow/develop.feature.md` — 完整开发流程
- [Superpowers writing-plans](https://github.com/obra/superpowers) — 设计来源
