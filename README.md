# Security Dev Skills

> 独立的标准化开发流程 skill 仓库，适用于任何 coding agent。

## 这是什么

一套覆盖完整开发生命周期的 skill 体系，解决三个核心问题：

1. **文档散乱** — 统一文档格式和同步机制
2. **文档更新无强制** — 代码变更后自动触发文档更新
3. **测试能力不足** — 从用户视角验证功能，不只是编译通过

## 支持的 Coding Agent

| Agent | 配置文件 | 状态 |
|-------|---------|------|
| [Claude Code](https://claude.ai/code) | `CLAUDE.md` | ✓ 已测试 |
| [Codex](https://github.com/openai/codex) | `AGENTS.md` | ✓ 支持 |
| [Cursor](https://cursor.sh) | `.cursorrules` | ✓ 支持 |
| [OpenCode](https://github.com/opencode-ai/opencode) | `AGENTS.md` | ✓ 支持 |
| [Windsurf](https://codeium.com/windsurf) | `.windsurfrules` | ✓ 支持 |
| [Aider](https://aider.chat) | `.aider.conf.yml` | ✓ 支持 |
| 其他 | 参考 INSTALL.md | ✓ 通用 |

## 安装方式

### 方式一：人类手动安装

```bash
# 1. 克隆仓库
git clone git@github.com:P0m32Kun/security-dev-skills.git ~/.security-dev-skills

# 2. 进入目录
cd ~/.security-dev-skills

# 3. 运行安装脚本（自动检测已安装的 agent 并创建软链接）
./install.sh
```

安装脚本会自动：
- 检测已安装的 Coding Agent
- 创建软链接到各 agent 的 skill 目录
- 更新 agent 配置文件
- 安装依赖（Semble, CodeGraph 等）

#### 指定 Agent 安装

```bash
# 只配置 Claude Code
./install.sh --agent claude-code

# 只配置 Cursor
./install.sh --agent cursor

# 查看支持的 agent
./install.sh --list-agents
```

### 方式二：Agent 自动安装

**打开你的 coding agent，输入：**

```
请阅读 https://github.com/P0m32Kun/security-dev-skills/blob/main/INSTALL.md 并按照说明安装。
```

**或者直接粘贴 INSTALL.md 的内容给 agent。**

Agent 会自动：
1. 克隆仓库到 `~/.security-dev-skills`
2. 运行安装脚本
3. 创建软链接到自己的 skill 目录
4. 配置 MCP 服务器

## 安装后验证

```bash
# 检查仓库是否克隆成功
ls ~/.security-dev-skills/SKILL.md

# 检查软链接（以 Claude Code 为例）
ls -la ~/.claude/skills/security-dev-skills

# 检查 MCP 配置（Claude Code）
cat ~/.claude/settings.json | grep -A 3 "mcpServers"

# 检查依赖是否安装
which uv
which git
```

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

## Skill 索引

| 类别 | Skill | 文件 | 用途 |
|------|-------|------|------|
| 编排器 | develop.feature | `workflow/develop.feature.md` | 完整需求开发流程 |
| 编排器 | retrospective | `workflow/retrospective.md` | 开发完成后的回顾与优化 |
| 文档 | doc-sync | `docs/sync.md` | 代码变更后同步文档 |
| 文档 | doc-validate | `docs/validate.md` | 文档一致性校验 |
| 测试 | test-strategy | `testing/strategy.md` | 测试策略选择 |
| 测试 | e2e-write | `testing/e2e-write.md` | E2E 测试编写 |
| 测试 | verify | `testing/verify.md` | 用户视角功能验证 |
| 安全 | security-research | `security/research.md` | 安全工具/方案调研 |
| 安全 | poc | `security/poc.md` | PoC 编写与验证 |
| 安全 | tool-integrate | `security/tool-integrate.md` | 安全工具集成 |
| 发布 | deploy | `release/deploy.md` | 发布部署流程 |

## 外部依赖

| 类型 | 名称 | 用途 | 必需 |
|------|------|------|------|
| MCP | Semble | 快速代码搜索（节省 98% token） | ✓ |
| MCP | CodeGraph | 代码知识图谱 | ✓ |
| MCP | AgentMemory | 持久记忆管理 | — |
| MCP | Context7 | 实时文档查询 | — |
| MCP | Playwright | 浏览器自动化 | — |
| MCP | Agent Browser | AI 浏览器 | — |
| 工具 | uv | Python 包管理器 | ✓ |
| 工具 | Docker | 容器化（仅部署场景需要） | — |
| 工具 | Git | 版本控制 | ✓ |

## 自动更新

```bash
# 检查更新
./auto-update.sh --check

# 执行更新
./auto-update.sh

# 设置定时更新（每天凌晨 3 点）
./auto-update.sh --setup-cron
```

## 目录结构

```
security-dev-skills/
├── SKILL.md                      # 体系总览（必读）
├── CONTEXT.md                    # 领域知识
├── INSTALL.md                    # 安装说明（给 agent 用）
├── install.sh                    # 安装脚本
├── auto-update.sh                # 自动更新脚本
├── dependencies.yaml             # 依赖清单
├── workflow/
│   ├── develop.feature.md        # 编排器：完整需求开发流程
│   └── retrospective.md          # 回顾环节
├── docs/
│   ├── sync.md                   # 文档同步
│   ├── validate.md               # 文档一致性校验
│   ├── templates/                # 文档模板
│   ├── best-practices.md         # 优秀设计模式
│   └── dependencies.md           # 依赖管理文档
├── testing/
│   ├── strategy.md               # 测试策略选择
│   ├── e2e-write.md              # E2E 测试编写
│   └── verify.md                 # 用户视角功能验证
├── security/
│   ├── research.md               # 安全工具/思路调研
│   ├── poc.md                    # PoC 编写
│   └── tool-integrate.md         # 工具集成
└── release/
    └── deploy.md                 # 发布部署流程
```

## 设计理念

我们是**独立的 skill 仓库**，不依赖外部 skill。学习优秀仓库的设计理念，自己实现：

| 仓库 | 学到的理念 |
|------|-----------|
| [superpowers](https://github.com/obra/superpowers) | HARD-GATE 阻断、Anti-Patterns |
| [gstack](https://github.com/garrytan/gstack) | 模板化、版本管理 |
| [karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | 行为准则、防 LLM 错误 |
| [mattpocock/skills](https://github.com/mattpocock/skills) | 渐进式披露、CONTEXT.md |

## 贡献

1. 每个 skill 是一个独立的 `.md` 文件
2. 遵循 SKILL.md 中定义的文件格式规范
3. 新增 skill 需更新 SKILL.md 的索引

## License

MIT
