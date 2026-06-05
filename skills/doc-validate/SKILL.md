---
name: doc-validate
description: >
  Use when validating documentation consistency, checking doc accuracy,
  or before PR submission. Use when user says "文档校验", "一致性检查",
  "doc validate", "check docs".
---

# 文档一致性校验

## Overview

PR 提交前校验文档一致性：时间戳对比、字段反向索引检查、frontmatter 完整性。目标是零过期文档、零无效引用。

## When to Use

- PR 提交前校验文档是否与代码一致
- 检查文档中的代码引用是否仍然有效
- 用户说"文档校验"、"一致性检查"

**何时不用**：
- 文档还没更新（先跑 `doc-sync`）
- 只需要更新文档，不需要校验 → 用 `doc-sync`

> PR 提交前校验文档一致性。

## 前置条件

- 文档已更新
- 代码已变更

## 核心原则

1. **零过期文档** — 所有文档都是最新的
2. **零无效引用** — 所有代码引用都是有效的
3. **完整性** — 所有文档都有完整的 frontmatter

## 流程

### 1. 时间戳对比

检查文档的 `last_updated` 时间是否在代码变更之后：

```bash
# 获取代码最后变更时间
git log -1 --format="%ai" -- path/to/code

# 获取文档最后更新时间
grep "last_updated:" docs/api.md
```

### 2. 字段反向索引检查

检查文档中引用的代码是否仍然存在：

```bash
# 检查文档中引用的函数是否存在
grep -o "function_name" docs/api.md | while read func; do
  if ! grep -r "function $func" src/; then
    echo "WARNING: $func not found in code"
  fi
done
```

### 3. Frontmatter 完整性

检查文档是否有完整的 frontmatter：

```yaml
---
title: 文档标题
last_updated: 2024-01-01
author: 作者
---
```

### 4. 输出校验报告

```markdown
## 文档校验报告

### 校验时间
[YYYY-MM-DD HH:MM]

### 校验结果
- **过期文档**：0 个
- **无效引用**：0 个
- **Frontmatter 缺失**：0 个

### 详细检查
- [ ] README.md — ✅ 最新
- [ ] docs/api.md — ✅ 最新
- [ ] docs/config.md — ⚠️ 需要更新

### 建议
- 更新 docs/config.md 的配置说明
```

## 完成标准

- [ ] 零过期文档
- [ ] 零无效代码引用
- [ ] 所有文档 frontmatter 完整
- [ ] 校验报告已输出

## Red Flags — STOP

当你有以下任何想法时，**停下来重新检查**：

- "我刚改的，肯定对"
- "lint 通过就行"
- "肉眼扫一遍"
- "文档校验太严了"
- "CI 会帮我查"

**所有这些都意味着你正在合理化跳过流程。回到 doc-validate 的第一步。**

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "我刚更新过文档" | 你上次说这话时漏了 3 处 |
| "lint 通过了" | lint 不检查内容一致性 |
| "文档小改不用查" | 小改可能引入大不一致 |
| "校验脚本太严" | 严是为了零过期文档 |
| "PR reviewer 会查" | Reviewer 不会替你跑校验 |

## 参考

- `skills/doc-sync/` — 文档同步
- `skills/develop-feature/` — 完整开发流程
