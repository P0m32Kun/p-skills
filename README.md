# P-Skills — 结构化开发技能体系

> 覆盖完整开发生命周期的 skill 仓库，**agent-agnostic**，可在 Claude Code / Codex / Cursor / OpenCode / pi / Qoder CLI / Aider / Gemini 等任何支持 skill 加载的 coding agent 上使用。

## 这是什么

一套覆盖完整开发生命周期的 skill 体系，基于 [mattpocock/skills](https://github.com/mattpocock/skills) 和 [obra/superpowers](https://github.com/obra/superpowers) 的设计理念。

### 核心特性

- **Agent-Agnostic** — 不绑定任何 agent，skill 内容只用通用术语；工具映射在 `docs/tools-reference.md`
- **扁平结构** — 每个 skill 独立可发现
- **自动触发** — description 作为触发条件
- **HARD-GATE** — 阻断机制确保流程执行
- **Bootstrap** — 会话入口强制检查 skill
- **Plugin 分发** — 通过各 agent 的 plugin marketplace 安装

## 支持的 Agent

| Agent | 安装方式 |
|-------|---------|
| Claude Code | `/plugin install p-skills` 或 `install.sh` |
| Codex CLI / App | `/plugins` 搜索 `p-skills` 或 `install.sh` |
| Cursor | `/add-plugin p-skills` 或 `install.sh` |
| OpenCode | `.opencode/INSTALL.md` 或 `install.sh` |
| Gemini CLI | `gemini extensions install <repo>` |
| Qoder CLI / pi / Aider / Reasonix / Windsurf / Cline / Continue | `install.sh` |
| 任何支持 skill/rules 加载的 agent | 把 `skills/` 目录复制到 agent 的 skill 路径 |

详见 `AGENTS.md`（任何 agent 的通用入口）和 `INSTALL.md`。

## Skill 列表

| Skill | 触发条件 | 用途 |
|-------|---------|------|
| **bootstrap** | 会话开始 | 强制检查适用的 skill |
| **brainstorming** | 设计讨论、方案探索 | 需求讨论与设计探索 |
| **writing-plans** | 编写实施计划 | 实施计划编写 |
| **develop-feature** | 新需求开发 | 完整开发流程编排 |
| **fix-bug** | 修复 bug、故障排查 | 标准化 Bug 修复 |
| **tdd** | TDD、测试驱动 | 测试驱动开发 |
| **bdd** | BDD、行为驱动、Gherkin | 行为驱动开发 |
| **test-strategy** | 测试策略 | 测试策略选择 |
| **verify** | 用户验证、验收测试 | 用户视角验证 |
| **e2e-write** | 编写 E2E 测试 | E2E 测试编写 |
| **doc-sync** | 文档同步 | 代码变更后同步文档 |
| **doc-validate** | 文档校验 | 文档一致性校验 |
| **deploy** | 发布部署 | 发布部署流程 |
| **retrospective** | 回顾总结 | 开发回顾与优化 |
| **security-research** | 安全调研 | 安全工具/方案调研 |
| **security-poc** | PoC 编写 | PoC 编写与验证 |
| **security-integrate** | 安全工具集成 | 安全工具集成到 CI/CD |
| **writing-skills** | 创建 skill | 创建/编辑/改进 skill（元技能） |
| **subagent-driven-development** | Subagent 驱动开发 | 按 plan 顺序派 fresh subagent 实现 + 双阶段 review |
| **dispatching-parallel-agents** | 并行 subagent 调度 | 并行派多个独立 subagent 做独立任务 |

## 安装

### 快速安装

```bash
# 克隆仓库
git clone git@github.com:P0m32Kun/p-skills.git ~/.p-skills

# 运行安装脚本
cd ~/.p-skills
./scripts/link-skills.sh
```

### 安装脚本做了什么

```bash
# 为每个 skill 创建扁平 symlink 到 agent 的 skill 根目录
# （agent 通常只按 <name>/SKILL.md 一层发现，不会递归 <repo>/skills/）
~/.pi/agent/skills/p-skills/bootstrap    -> ~/.p-skills/skills/bootstrap
~/.pi/agent/skills/p-skills/brainstorming -> ~/.p-skills/skills/brainstorming
~/.pi/agent/skills/p-skills/fix-bug      -> ~/.p-skills/skills/fix-bug
... (共 20 个 skill)
```

### 预览安装（不实际创建）

```bash
./scripts/link-skills.sh --dry-run
```

## 目录结构

```
~/.p-skills/
├── skills/                        ← 所有 skill（扁平）
│   ├── bootstrap/                 ← 会话入口
│   │   └── SKILL.md
│   ├── brainstorming/
│   │   └── SKILL.md
│   ├── writing-plans/
│   │   └── SKILL.md
│   ├── develop-feature/
│   │   └── SKILL.md
│   ├── fix-bug/
│   │   └── SKILL.md
│   ├── tdd/
│   │   └── SKILL.md
│   ├── test-strategy/
│   │   └── SKILL.md
│   ├── verify/
│   │   └── SKILL.md
│   ├── e2e-write/
│   │   └── SKILL.md
│   ├── doc-sync/
│   │   └── SKILL.md
│   ├── doc-validate/
│   │   └── SKILL.md
│   ├── deploy/
│   │   └── SKILL.md
│   ├── retrospective/
│   │   └── SKILL.md
│   ├── security-research/
│   │   └── SKILL.md
│   ├── security-poc/
│   │   └── SKILL.md
│   └── security-integrate/
│       └── SKILL.md
├── scripts/
│   ├── link-skills.sh             ← 安装脚本
│   └── list-skills.sh             ← 列出所有 skill
├── integrations/                  ← 外部集成
├── docs/                          ← 参考文档
├── CONTEXT.md                     ← 项目上下文
└── README.md
```

## 使用方式

### 自动触发

安装后，pi 会根据 description 自动触发对应的 skill：

```
用户：帮我修复这个 bug
→ pi 自动加载 fix-bug skill
→ 执行标准化 Bug 修复流程
```

### 手动触发

```
用户：/brainstorming
→ pi 加载 brainstorming skill
→ 执行需求讨论流程
```

### 会话入口

`bootstrap` skill 在每次会话开始时自动加载，确保：
1. 所有 skill 能被正确发现
2. 在行动前检查适用的 skill
3. 不找理由跳过 skill

## 设计来源

| 仓库 | 学到的理念 |
|------|-----------|
| [mattpocock/skills](https://github.com/mattpocock/skills) | 扁平结构、link-skills.sh 安装、description 作为触发条件 |
| [obra/superpowers](https://github.com/obra/superpowers) | bootstrap skill、HARD-GATE 阻断、强制 skill 检查 |
| [karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | 行为准则、防 LLM 错误 |

## 更新

```bash
cd ~/.p-skills
git pull --rebase
./scripts/link-skills.sh
```

## 卸载

```bash
# 预览会移除哪些 symlink
./scripts/unlink-skills.sh --dry-run

# 移除所有 symlink
./scripts/unlink-skills.sh

# 移除 symlink 并删除整个仓库
./scripts/unlink-skills.sh --all
```

## 清理旧版 symlink

如果你之前使用过 `p-skills` 或 `security-dev-skills` 的整体 symlink，需要先清理：

```bash
# 预览会清理什么
./scripts/cleanup-old-symlinks.sh --dry-run

# 执行清理并创建新的 per-skill symlink
./scripts/cleanup-old-symlinks.sh

# 非交互模式（自动确认）
./scripts/cleanup-old-symlinks.sh --auto
```

这会移除以下目录中的旧 symlink：
- `~/.pi/agent/skills/p-skills`
- `~/.claude/skills/p-skills`
- `~/.claude/skills/security-dev-skills`
- `~/.cursor/skills/p-skills`
- `~/.cursor/skills/security-dev-skills`
- `~/.codex/skills/p-skills`

## 许可证

MIT License
