# Security Dev Skills — 设计文档

> 创建日期：2026-06-02
> 状态：已完成（2026-06-02）

## 1. 背景与目标

### 问题

当前开发工作流存在三个核心问题：

1. **文档散乱** — 文档分散在多个目录，格式不统一，新 agent 接手困难
2. **文档更新无强制机制** — 代码变更后文档还是旧的，靠人工自觉不可靠
3. **测试能力不足** — 只从代码角度测试（编译通过 = 通过），没有从用户视角验证功能是否真正实现

### 目标

创建一个独立的、可移植的 skill 仓库，定义标准化的开发流程。目标：

- 不绑定特定 coding agent（Claude Code、Cursor、Copilot 等都能用）
- 覆盖完整的开发生命周期：调研 → 设计 → 编码 → 文档 → 测试 → 发布
- 每个阶段有明确的完成标准，不能跳过
- 渐进式演进，后续按需添加新 skill

## 2. 架构设计

### 2.1 整体架构：编排器 + 领域 Skill

采用混合架构：

- **编排器**（`workflow/develop.feature.md`）定义完整需求开发流程，串联各阶段
- **领域 Skill** 按关注域分组，每个 skill 可独立使用，也可被编排器调用

```
security-dev-skills/
├── README.md                         # 仓库说明 + 快速开始
├── SKILL.md                          # 体系总览（必读）
├── DESIGN.md                         # 本设计文档（实施后可归档）
├── CHANGELOG.md                      # Skill 变更日志
├── workflow/
│   └── develop.feature.md            # 编排器：完整需求开发流程
├── docs/
│   ├── sync.md                       # 文档同步
│   ├── validate.md                   # 文档一致性校验
│   └── templates/
│       ├── feature.md                # 功能文档模板
│       ├── api.md                    # API 文档模板
│       └── architecture.md           # 架构文档模板
├── testing/
│   ├── strategy.md                   # 测试策略选择
│   ├── e2e-write.md                  # E2E 测试编写
│   └── verify.md                     # 用户视角功能验证
├── security/
│   ├── research.md                   # 安全工具/思路调研
│   ├── poc.md                        # PoC 编写
│   └── tool-integrate.md             # 工具集成
└── release/
    └── deploy.md                     # 发布部署流程
```

### 2.2 流程图

```
┌─────────┐    ┌─────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌─────────┐
│ Research │───▶│ Design  │───▶│ Implement│───▶│ Doc-Sync │───▶│  Verify  │───▶│ Release │
│  调研    │    │  设计    │    │  编码     │    │ 文档同步  │    │  验证    │    │  发布   │
└─────────┘    └─────────┘    └──────────┘    └──────────┘    └──────────┘    └─────────┘
     │              │               │               │               │               │
  security/     (复用外部       testing/        docs/sync.md    testing/        release/
  research.md    brainstorming   strategy.md    docs/validate   e2e-write.md    deploy.md
                 + writing-plans + TDD skill)                   verify.md
```

### 2.3 阶段职责与阻断条件

| 阶段 | 输入 | 输出 | 阻断条件 |
|------|------|------|---------|
| Research | 需求描述 | 调研报告（工具/方案/竞品） | 无调研不进入设计 |
| Design | 调研结果 | 设计文档（spec） | 无 spec 不进入编码 |
| Implement | 设计文档 | 可运行代码 + 单元测试 | 编译/测试不通过不进入文档同步 |
| Doc-Sync | 代码变更 diff | 更新后的文档 | 文档未同步不进入验证 |
| Verify | 功能代码 + 文档 | E2E 测试通过报告 | 用户视角验证不通过不进入发布 |
| Release | 验证通过的代码 | 发布产物（Docker 镜像/二进制） | — |

**允许回退**：Verify 阶段发现问题可回退到 Implement。

**小需求合并**：Research + Design 可压缩为一个步骤。

## 3. Skill 文件格式

### 3.1 Frontmatter 规范

每个 skill 文件必须包含 YAML frontmatter：

```yaml
---
name: skill-name              # 必填，kebab-case
description: 一句话描述        # 必填
version: 1.0.0                # 必填，语义化版本
tags: [tag1, tag2]            # 可选，用于分类检索
triggers:                     # 可选，触发条件（自然语言）
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

### 3.2 文件体结构

```markdown
# Skill 标题

## 前置条件
- 开始前必须满足的条件

## 流程
1. 步骤一
2. 步骤二
...

## 完成标准
- 可验证的完成条件（不是"我觉得做完了"）

## 参考
- 相关文档、示例、外部链接
```

### 3.3 可移植性约束

- **不依赖特定 agent 的工具调用语法** — 只描述流程和规则
- **用自然语言描述触发条件** — 不写正则或代码
- **输入输出用通用格式** — JSON Schema 描述
- **每个 skill 自包含** — 一个 md 文件就是一个完整 skill

## 4. 领域 Skill 详细设计

### 4.1 文档同步 `docs/sync.md`

**触发时机**：每次代码变更后

**流程**：
1. 检测变更范围（git diff 或 agent 编辑记录）
2. 根据文档同步约束表匹配受影响的文档
3. 更新对应文档内容和 `last_updated` 时间戳
4. 输出变更清单

**完成标准**：所有受影响文档已更新

### 4.2 文档校验 `docs/validate.md`

**触发时机**：PR 提交前、CI 检查

**流程**：
1. 扫描文档 `last_updated` 对比代码最后修改时间
2. 检查字段反向索引与代码一致性
3. 检查 frontmatter 完整性
4. 输出不一致报告

**完成标准**：零不一致

### 4.3 测试策略 `testing/strategy.md`

**触发时机**：进入 Implement 前

**流程**：
1. 分析变更类型（新增功能/修 bug/重构/配置变更）
2. 选择测试层级：Unit / Integration / E2E
3. 输出测试计划

### 4.4 E2E 测试编写 `testing/e2e-write.md`

**触发时机**：用户流程变更时

**流程**：
1. 阅读项目 E2E 测试约定
2. 编写 spec（文件头注释、UI 操作、加载/空/错误态覆盖）
3. Docker 环境运行验证

**完成标准**：spec 通过、覆盖用户视角的关键路径

### 4.5 功能验证 `testing/verify.md`

**触发时机**：Implement 完成后、Release 前

**核心理念**：编译通过 ≠ 功能实现

**流程**：
1. 列出用户验收条件（不是代码层面的）
2. 执行 E2E 测试或手动验证
3. 输出验证报告

**完成标准**：所有用户验收条件满足

### 4.6 安全调研 `security/research.md`

**触发时机**：新需求涉及安全工具/技术选型

**流程**：
1. 明确调研目标
2. 搜索市面上的工具/方案
3. 对比分析
4. 输出调研报告 + 推荐方案

### 4.7 PoC 编写 `security/poc.md`

**触发时机**：验证漏洞/安全假设

**流程**：
1. 明确目标资产和漏洞类型
2. 编写 PoC 脚本（独立可运行）
3. 靶场环境验证
4. 输出 PoC 脚本 + 验证报告

### 4.8 工具集成 `security/tool-integrate.md`

**触发时机**：集成新安全工具

**流程**：
1. 了解工具输入输出格式
2. 编写 parser
3. 编写 pipeline tool
4. 集成测试
5. 更新文档

### 4.9 发布部署 `release/deploy.md`

**触发时机**：功能开发完成

**流程**：
1. 版本号确定（PATCH/MINOR/MAJOR）
2. Docker 镜像构建（多平台）
3. 推送到 ACR
4. 更新 CHANGELOG
5. 创建 Git tag + GitHub Release

## 5. 与外部 Skill 的关系

| 我们的 Skill | 复用/参考 | 关系 |
|-------------|----------|------|
| `workflow/develop.feature` | superpowers 的 brainstorming/writing-plans | 编排器引用它们作为 Design 阶段实现 |
| `testing/e2e-write` | mattpocock 的 tdd | 参考 red-green-refactor 思路 |
| `docs/sync` | 无 | 完全新建，基于 CLAUDE.md 文档同步约束 |
| `security/*` | 无 | 完全新建 |

**原则**：我们的 skill 定义"做什么"和"完成标准"，具体"怎么做"可引用外部 skill。

## 6. 实施计划

### Phase 1：基础框架

1. 创建目录结构
2. 编写 `README.md`（仓库说明）
3. 编写 `SKILL.md`（体系总览）
4. 编写 `CHANGELOG.md`

### Phase 2：核心 Skill

按优先级实施（对应用户提出的 A → B → C）：

1. `docs/sync.md` + `docs/validate.md` + `docs/templates/` — 解决文档问题
2. `testing/strategy.md` + `testing/e2e-write.md` + `testing/verify.md` — 解决测试问题
3. `workflow/develop.feature.md` — 编排器，串联所有 skill

### Phase 3：安全开发 Skill

4. `security/research.md`
5. `security/poc.md`
6. `security/tool-integrate.md`

### Phase 4：发布 Skill

7. `release/deploy.md`

## 7. 验证方式

实施完成后，用以下方式验证：

1. **自检**：每个 skill 文件的 frontmatter 完整、流程清晰、完成标准可验证
2. **试运行**：在 Anchor 项目中用新 skill 体系走一个完整需求开发流程
3. **可移植性测试**：在另一个 coding agent 中加载 skill 仓库，验证能否正常使用

---

> **实施完成记录**（2026-06-02）
>
> 所有四个阶段已实施完成：
> - Phase 1-2：文档 + 测试 skill ✅
> - Phase 3：安全 skill ✅
> - Phase 4：发布 skill ✅
> - 额外：brainstorming、writing-plans、tdd 三个自建 skill ✅
> - 额外：集成 AgentMemory、CodeGraph、Semble skills ✅
>
> 详见 `CHANGELOG.md`
