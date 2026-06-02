---
name: retrospective
description: 开发完成后的回顾与优化，记录问题、踩坑、工具失败、skill 不好用的地方
version: 1.0.0
tags: [workflow, retrospective, improvement]
triggers:
  - "开发完成后"
  - "回顾总结"
  - "复盘"
  - "retrospective"
inputs:
  - name: development_context
    description: 本次开发的上下文（需求、技术栈、时间）
    required: true
  - name: issues_encountered
    description: 遇到的问题列表
    required: false
outputs:
  - name: retro_report
    description: 回顾报告 + 优化建议
---

# 开发回顾与优化

> **核心理念**：每次开发完成后，回顾过程中的问题，持续优化 skill 体系。

## 前置条件
- 本次需求开发已完成（Release 阶段通过）
- 或开发过程中遇到重大阻碍需要暂停反思

## 流程

### 1. 收集问题

从以下维度收集本次开发过程中遇到的问题：

#### 工具调用失败

| 工具 | 失败场景 | 错误信息 | 频率 |
|------|---------|---------|------|
| git | push 被拒绝 | permission denied | 1 次 |
| docker | 构建超时 | context deadline exceeded | 2 次 |
| npm | 依赖安装失败 | ERESOLVE unable to resolve | 3 次 |

#### 常见报错

| 错误类型 | 错误信息 | 出现次数 | 根因 |
|---------|---------|---------|------|
| 编译错误 | Cannot find module 'xxx' | 5 次 | 依赖未安装 |
| 类型错误 | Property 'xxx' does not exist | 3 次 | 接口定义不一致 |
| 运行时错误 | ENOENT: no such file or directory | 2 次 | 路径错误 |

#### 踩过的坑

| 坑 | 描述 | 影响 | 如何避免 |
|----|------|------|---------|
| 环境差异 | 本地 OK，CI 失败 | 浪费 2 小时 | 先在 Docker 环境测试 |
| 文档过时 | 按文档操作报错 | 浪费 1 小时 | 先检查文档更新时间 |
| 依赖冲突 | 新旧版本不兼容 | 浪费 3 小时 | 锁定依赖版本 |

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
## 问题分析

### 问题 1：Docker 构建超时

**现象**：Docker 构建过程中超时，导致 CI 失败

**根因**：
- Dockerfile 未使用多阶段构建
- 基础镜像过大（1.2GB）
- 未利用构建缓存

**影响**：
- CI 流程阻塞
- 浪费 2 小时排查

**解决方案**：
- 优化 Dockerfile，使用多阶段构建
- 选择更小的基础镜像（alpine）
- 合理利用 Docker 缓存

**预防措施**：
- 在 skill 中增加 Dockerfile 最佳实践检查
- CI 环境预热 Docker 缓存
```

### 3. 量化影响

统计本次开发的时间和 token 浪费：

```markdown
## 资源浪费统计

### 时间浪费
| 原因 | 浪费时间 | 占比 |
|------|---------|------|
| 工具调用失败 | 2 小时 | 20% |
| 踩坑排查 | 3 小时 | 30% |
| Skill 不好用 | 1 小时 | 10% |
| **总计** | **6 小时** | **60%** |

### Token 浪费
| 原因 | 浪费 Token | 占比 |
|------|-----------|------|
| 重复调试 | 50k | 25% |
| 错误方向 | 30k | 15% |
| 文档查询 | 20k | 10% |
| **总计** | **100k** | **50%** |
```

### 4. 输出优化建议

```markdown
## 优化建议

### Skill 优化

#### test-strategy.md
**问题**：测试层级选择不够明确，导致测试覆盖不足或过度

**改进建议**：
1. 增加决策树，根据变更类型自动推荐测试层级
2. 增加测试覆盖率阈值
3. 增加测试优先级排序

**修改内容**：
```markdown
### 决策树

变更类型 → 影响范围 → 测试层级

新增功能：
  - 核心功能 → Unit + Integration + E2E
  - 辅助功能 → Unit + Integration
  - 配置变更 → Integration

修 bug：
  - 逻辑错误 → Unit + Integration
  - 样式问题 → E2E
  - 性能问题 → Unit + Benchmark
```

#### verify.md
**问题**：验收条件太模糊，导致验证不充分

**改进建议**：
1. 使用 SMART 原则定义验收条件
2. 增加验收条件模板
3. 增加自动化验证脚本

**修改内容**：
```markdown
### SMART 验收条件

- Specific：具体的用户操作
- Measurable：可测量的结果
- Achievable：可实现的
- Relevant：相关的用户价值
- Time-bound：可测试的时间约束

示例：
- ✗ "用户可以登录"
- ✓ "用户输入正确用户名和密码，点击登录按钮，2秒内跳转到首页，显示用户名"
```

### 流程优化

#### 增加环境检查
**问题**：环境差异导致本地 OK、CI 失败

**改进建议**：
1. 在 Implement 阶段前增加环境检查步骤
2. 使用 Docker 作为开发环境
3. CI 环境与本地环境保持一致

#### 增加文档校验
**问题**：文档过时导致按文档操作报错

**改进建议**：
1. 在 Doc-Sync 阶段增加文档时效性检查
2. 文档超过 30 天未更新标记为"可能过时"
3. 操作前先检查文档最后更新时间

### 工具优化

#### Docker 构建
**问题**：构建超时

**改进建议**：
1. 使用多阶段构建
2. 选择更小的基础镜像
3. 合理利用构建缓存
4. 预热 CI 环境缓存

#### 依赖管理
**问题**：依赖冲突

**改进建议**：
1. 锁定依赖版本（package-lock.json）
2. 定期更新依赖（dependabot）
3. 使用 workspace 隔离依赖
```

### 5. 更新 Skill

根据优化建议，更新对应的 skill 文件：

```bash
# 更新 skill 文件
vim testing/strategy.md
vim testing/verify.md

# 更新 CHANGELOG
vim CHANGELOG.md

# 提交更改
git add .
git commit -m "refactor: 根据回顾优化 test-strategy 和 verify skill"
```

## 完成标准
- [ ] 问题已收集（工具失败、报错、踩坑、skill 评估）
- [ ] 根因已分析
- [ ] 影响已量化（时间、token）
- [ ] 优化建议已输出
- [ ] Skill 已更新（如需要）

## 参考
- `workflow/develop.feature.md` — 完整需求开发流程
- [Karpathy Guidelines](https://github.com/multica-ai/andrej-karpathy-skills) — LLM 编码常见错误
- [mattpocock/skills](https://github.com/mattpocock/skills) — Skill 设计最佳实践
