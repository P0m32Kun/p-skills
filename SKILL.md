# Security Dev Skills — 体系总览

> 本文档是 skill 体系的入口，所有 agent 必读。

## 核心理念

1. **流程强制** — 每个阶段有明确的完成标准，不能跳过
2. **可移植** — 不绑定特定 coding agent，用自然语言描述
3. **自包含** — 一个 `.md` 文件就是一个完整 skill

## 开发流程

```
Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
   │          │          │           │          │         │          │
安全调研    设计文档    编码+测试    文档同步    用户验证    发布部署    回顾优化
```

### 阻断条件

| 阶段 | 阻断条件 |
|------|---------|
| Research | 无调研不进入 Design |
| Design | 无 spec 不进入 Implement |
| Implement | 编译/测试不通过不进入 Doc-Sync |
| Doc-Sync | 文档未同步不进入 Verify |
| Verify | 用户视角验证不通过不进入 Release |

### 允许的灵活性

- **回退**：Verify 发现问题可回退到 Implement
- **小需求合并**：Research + Design 可压缩为一个步骤

## Skill 文件格式

### Frontmatter

```yaml
---
name: skill-name              # 必填，kebab-case
description: 一句话描述        # 必填
version: 1.0.0                # 必填，语义化版本
tags: [tag1, tag2]            # 可选
triggers:                     # 可选，触发条件
  - "关键词或意图描述"
inputs:                       # 可选，输入契约
  - name: param_name
    description: 参数说明
    required: true
outputs:                      # 可选，输出契约
  - name: output_name
    description: 输出说明
---
```

### 文件体

```markdown
# Skill 标题

## 前置条件
- 开始前必须满足的条件

## 流程
1. 步骤一
2. 步骤二
...

## 完成标准
- 可验证的完成条件

## 参考
- 相关文档、示例、外部链接
```

## Skill 索引

### 编排器

| Skill | 文件 | 用途 |
|-------|------|------|
| develop.feature | `workflow/develop.feature.md` | 完整需求开发流程 |
| retrospective | `workflow/retrospective.md` | 开发完成后的回顾与优化 |

### 文档

| Skill | 文件 | 用途 |
|-------|------|------|
| doc-sync | `docs/sync.md` | 代码变更后同步文档 |
| doc-validate | `docs/validate.md` | PR 提交前校验文档一致性 |

### 测试

| Skill | 文件 | 用途 |
|-------|------|------|
| test-strategy | `testing/strategy.md` | 根据变更类型选择测试策略 |
| e2e-write | `testing/e2e-write.md` | 编写 E2E 测试 |
| verify | `testing/verify.md` | 用户视角功能验证 |

### 安全

| Skill | 文件 | 用途 |
|-------|------|------|
| security-research | `security/research.md` | 安全工具/方案调研 |
| poc | `security/poc.md` | PoC 编写与验证 |
| tool-integrate | `security/tool-integrate.md` | 安全工具集成 |

### 发布

| Skill | 文件 | 用途 |
|-------|------|------|
| deploy | `release/deploy.md` | 发布部署流程 |

## 使用方式

### 新需求开发

1. 阅读 `workflow/develop.feature.md`
2. 按流程依次执行各阶段
3. 每个阶段使用对应的 skill

### 单独使用某个 skill

直接阅读对应的 `.md` 文件，按流程执行。

## 与外部 Skill 的协作

- **Design 阶段**：可使用 superpowers 的 `brainstorming` + `writing-plans`
- **Implement 阶段**：可使用 mattpocock 的 `tdd` 进行测试驱动开发
- **其他 skill**：本仓库定义"做什么"和"完成标准"，"怎么做"可引用外部 skill
