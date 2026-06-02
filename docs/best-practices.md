# 优秀 Skill 设计模式

> 从优秀 skill 仓库吸收的设计理念，已集成到我们的 skill 体系中。
> 原始调研记录详见 `docs/analysis.md`。

## 已集成的设计模式

### 1. HARD-GATE 阻断机制（来自 superpowers）

**理念**：强制检查点，不能跳过。

**应用**：
```markdown
<HARD-GATE>
**阻断条件**：无调研不进入 Design

**检查项**：
- [ ] 需求背景已明确
- [ ] 技术方案已调研
- [ ] 调研报告已输出
</HARD-GATE>
```

**位置**：`workflow/develop.feature.md` 每个阶段都有 HARD-GATE。

---

### 2. Anti-Patterns 反模式（来自 superpowers）

**理念**：明确说明什么不能做，防止常见错误。

**应用**：
```markdown
## Anti-Patterns

- ✗ 跳过调研直接开始编码
- ✗ 只调研一个方案就决定
- ✗ 不看竞品，闭门造车
```

**位置**：所有 skill 文件都有 Anti-Patterns 章节。

---

### 3. 行为准则（来自 karpathy-skills）

**理念**：防止 LLM 常见错误，简洁有力的指导。

**应用**：
```markdown
## 核心原则

1. **流程强制** — 每个阶段有明确的完成标准，不能跳过
2. **可验证** — 每个输出必须可验证，不能依赖主观判断
3. **持续改进** — 每次开发完成后进行回顾，持续优化
```

**位置**：`SKILL.md` 和各 skill 文件的开头。

---

### 4. SMART 验收条件（来自 mattpocock）

**理念**：验收条件必须具体、可测量、可实现、相关、有时限。

**应用**：
```markdown
### SMART 验收条件

| 原则 | 说明 | 示例 |
|------|------|------|
| **S**pecific | 具体的用户操作 | "输入正确用户名和密码，点击登录按钮" |
| **M**easurable | 可测量的结果 | "2秒内跳转到首页" |
| **A**chievable | 可实现的 | 不要写"永远不崩溃" |
| **R**elevant | 相关的用户价值 | "显示用户名，确认登录成功" |
| **T**ime-bound | 可测试的时间约束 | "登录态保持24小时" |
```

**位置**：`testing/verify.md`

---

### 5. 决策树（来自 mattpocock）

**理念**：用决策树指导选择，而不是模糊的建议。

**应用**：
```markdown
### 决策树：选择测试层级

变更类型？
├── 新增功能
│   ├── 核心功能 → Unit + Integration + E2E
│   └── 辅助功能 → Unit + Integration
├── 修 bug
│   ├── 逻辑错误 → Unit + Integration
│   └── 样式问题 → E2E
└── 重构
    └── 先补 Unit，再重构
```

**位置**：`testing/strategy.md`

---

### 6. CONTEXT.md 领域知识（来自 mattpocock）

**理念**：集中管理领域知识，供 skill 引用。

**应用**：
```markdown
# CONTEXT.md

## 术语表
| 术语 | 定义 |
|------|------|
| Skill | 一个独立的开发流程指南 |
| 编排器 | 串联多个 skill 的流程定义 |

## 技术栈
- 开发环境：macOS / Linux
- 容器化：Docker / Docker Compose
```

**位置**：`CONTEXT.md`

---

### 7. 渐进式披露（来自 mattpocock）

**理念**：先讲原则，再讲细节，最后讲示例。

**应用**：
```markdown
# Skill 标题

## 核心原则（先讲为什么）
1. 流程强制
2. 可验证
3. 持续改进

## 流程（再讲怎么做）
1. 步骤一
2. 步骤二

## 示例（最后看例子）
​```markdown
具体示例...
​```
```

**位置**：所有 skill 文件。

---

### 8. 模板化（来自 gstack）

**理念**：统一的格式，便于维护和扩展。

**应用**：
```yaml
---
name: skill-name
description: 一句话描述
version: 1.0.0
tags: [tag1, tag2]
triggers:
  - "触发条件"
inputs:
  - name: param
    description: 参数说明
    required: true
outputs:
  - name: output
    description: 输出说明
---
```

**位置**：所有 skill 文件的 frontmatter。

## 设计原则

### 独立性

我们是**独立的 skill 仓库**，不依赖外部 skill。学习优秀仓库的设计理念，但自己实现。

### 自包含

每个 skill 文件是自包含的，一个 `.md` 文件就是一个完整 skill。

### 可移植

不绑定特定 coding agent，用自然语言描述流程和规则。

### 持续改进

通过回顾环节，持续优化 skill 体系。

## 参考

- `SKILL.md` — 体系总览
- `CONTEXT.md` — 领域知识
- `workflow/retrospective.md` — 回顾环节
