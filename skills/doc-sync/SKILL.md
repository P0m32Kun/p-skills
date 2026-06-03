---
name: doc-sync
description: >
  Use when syncing documentation after code changes, updating docs, or when
  code changes affect documentation. Use when user says "文档同步", "更新文档",
  "doc sync", "update docs".
---

# 文档同步

> 代码变更后同步相关文档。

## 前置条件

- 代码已完成变更（编译通过）
- 项目有文档目录结构

## 核心原则

1. **文档随代码更新** — 代码变更必须同步文档
2. **一致性** — 文档与代码保持一致
3. **完整性** — 所有受影响文档都要更新

## 流程

### 1. 检测变更范围

```bash
# 查看变更的文件
git diff --name-only HEAD~1

# 查看变更的代码
git diff HEAD~1
```

### 2. 匹配受影响文档

根据变更的代码，确定受影响的文档：

| 代码变更 | 受影响文档 |
|---------|-----------|
| API 接口变更 | API 文档、README |
| 配置变更 | 配置文档、部署文档 |
| 依赖变更 | README、安装文档 |
| 功能变更 | 用户文档、README |
| 数据库变更 | 数据模型文档 |

### 3. 更新文档

更新所有受影响的文档：

```markdown
# 文档更新清单

### README.md
- [ ] 更新功能说明
- [ ] 更新安装步骤
- [ ] 更新配置说明

### docs/api.md
- [ ] 更新 API 接口
- [ ] 更新请求/响应示例

### CHANGELOG.md
- [ ] 添加变更记录
```

### 4. 输出变更清单

```markdown
## 文档同步变更清单

### 变更的代码文件
- `src/api/user.ts` — 添加用户注册接口
- `src/models/user.ts` — 修改用户模型

### 更新的文档
- `README.md` — 更新功能说明
- `docs/api.md` — 添加注册接口文档
- `CHANGELOG.md` — 添加变更记录

### 更新时间
[YYYY-MM-DD HH:MM]
```

## Anti-Patterns

- ✗ 代码变更后不更新文档
- ✗ 只更新部分文档
- ✗ 文档更新后不校验一致性
- ✗ 文档与代码不一致

## 完成标准

- [ ] 所有受影响文档已识别
- [ ] 所有受影响文档内容已更新
- [ ] 所有 `last_updated` 时间戳已更新
- [ ] 变更清单已输出

## 参考

- `docs/validate.md` — 文档一致性校验
- `workflow/develop.feature.md` — 完整开发流程
- [Docs as Code](https://docs-as-code.com/) — 文档即代码
