---
name: retrospective
description: >
  Use when doing development retrospective, post-mortem, or process
  improvement. Use when user says "回顾总结", "复盘", "retrospective",
  "post-mortem", "process improvement".
---

# 开发回顾与优化

## Overview

每次开发完成后，回顾过程中的问题，分析根因，量化影响，输出可执行的优化建议。持续改进 skill 体系。

## When to Use

- 开发完成后的回顾总结、复盘
- 开发过程中遇到重大阻碍需要暂停反思
- 用户说"回顾总结"、"复盘"、"retrospective"

**何时不用**：
- 开发还没完成（等 Release 阶段通过后再回顾）
- 只需要修 bug → 用 `fix-bug`

> 每次开发完成后，回顾过程中的问题，持续优化 skill 体系。

## 前置条件

- 本次需求开发已完成（Release 阶段通过）
- 或开发过程中遇到重大阻碍需要暂停反思

## 核心原则

1. **客观记录** — 记录事实，不带情绪
2. **根因分析** — 找到问题的根本原因
3. **可执行** — 优化建议要具体可执行
4. **持续改进** — 每次回顾都要有改进

## 流程

### 1. 收集问题

#### 工具调用失败

| 工具 | 失败场景 | 影响 | 解决方案 |
|------|---------|------|---------|
| Docker | 构建超时 | 阻塞部署 | 增加重试机制 |
| npm | 网络超时 | 阻塞安装 | 使用镜像源 |

#### 常见报错

| 错误 | 频率 | 根因 | 解决方案 |
|------|------|------|---------|
| TypeScript 类型错误 | 高 | 类型定义不完整 | 补充类型定义 |
| 测试超时 | 中 | 测试环境不稳定 | 增加超时时间 |

#### 踩过的坑

| 坑 | 影响 | 教训 |
|----|------|------|
| 数据库迁移顺序错误 | 生产环境故障 | 迁移脚本要有回滚 |
| 环境变量未配置 | 服务启动失败 | 启动前检查环境变量 |

#### Skill 评估

| Skill | 好用？ | 问题 | 改进建议 |
|-------|--------|------|---------|
| doc-sync | ✓ | — | — |
| test-strategy | ✗ | 测试层级选择不够明确 | 增加决策树 |
| e2e-write | ✓ | — | — |
| verify | ✗ | 验收条件太模糊 | 增加 SMART 原则 |

### 2. 分析根因

对每个问题进行根因分析：

```markdown
## 问题：测试超时

### 现象
- 测试经常超时，特别是 E2E 测试
- 超时后需要重新运行，浪费时间

### 根因分析
1. **直接原因**：测试等待时间设置太短
2. **根本原因**：测试环境不稳定，网络延迟高
3. **深层原因**：没有使用本地测试环境，依赖远程服务

### 影响
- 开发效率降低 20%
- CI/CD 流水线不稳定
```

### 3. 量化影响

```markdown
## 影响量化

### 时间影响
- 问题 1：每次浪费 10 分钟，每天发生 3 次 → 30 分钟/天
- 问题 2：每次浪费 30 分钟，每周发生 2 次 → 60 分钟/周

### 质量影响
- 问题 1：导致 2 次生产环境故障
- 问题 2：导致 5 次代码回滚

### 成本影响
- 开发效率降低：15%
- 测试覆盖率降低：10%
```

### 4. 输出优化建议

#### 流程优化

```markdown
### 增加环境检查

**问题**：环境变量未配置导致服务启动失败

**建议**：
1. 添加启动前环境检查脚本
2. 检查必需的环境变量
3. 检查依赖服务是否可用

**实施**：
```bash
# scripts/check-env.sh
#!/bin/bash
required_vars=("DATABASE_URL" "REDIS_URL" "API_KEY")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "ERROR: $var is not set"
    exit 1
  fi
done
```

### 增加文档校验

**问题**：文档与代码不一致

**建议**：
1. 在 CI/CD 中添加文档校验步骤
2. 代码变更时自动检查文档
3. 文档更新后自动校验一致性

**实施**：
```yaml
# .github/workflows/docs.yml
- name: Validate docs
  run: |
    npm run docs:validate
```
```

#### 工具优化

```markdown
### Docker 构建

**问题**：Docker 构建超时

**建议**：
1. 使用多阶段构建减少镜像大小
2. 使用缓存加速构建
3. 使用本地镜像仓库

**实施**：
```dockerfile
# 使用缓存
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
```

### 依赖管理

**问题**：依赖冲突导致构建失败

**建议**：
1. 使用 lockfile 锁定依赖版本
2. 定期更新依赖
3. 使用依赖检查工具

**实施**：
```bash
# 检查过期依赖
npm outdated

# 检查安全漏洞
npm audit

# 更新依赖
npm update
```
```

## 完成标准

- [ ] 所有问题已收集
- [ ] 根因已分析
- [ ] 影响已量化
- [ ] 优化建议已输出
- [ ] 建议已记录到 skill 体系

## Red Flags — STOP

当你有以下任何想法时，**停下来重新检查**：

- "这次没啥可复盘的"
- "下次再说"
- "反正改不了什么"
- "开发记录太麻烦"
- "时间紧，跳过回顾"

**所有这些都意味着你正在合理化跳过流程。回到 retrospective 的第一步。**

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "这次很顺利不用回顾" | 顺利时才是总结最佳实践的时机 |
| "问题都解决了" | 解决 ≠ 学到教训 |
| "下次再回顾" | 下次 = 永远不 |
| "回顾浪费时间" | 重复犯同样的错更浪费 |
| "没人看回顾文档" | 那是因为你没把结论落实到 skill |

## 参考

- `workflow/develop.feature.md` — 完整开发流程
- [Karpathy Guidelines](https://github.com/multica-ai/andrej-karpathy-skills) — LLM 编码常见错误
- [mattpocock/skills](https://github.com/mattpocock/skills) — Skill 设计最佳实践
- [Google SRE](https://sre.google/sre-book/postmortem-culture/) — 事后回顾
