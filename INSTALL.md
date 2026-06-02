# Security Dev Skills — 安装说明

> 本文件供 coding agent（如 Claude Code）自动安装使用。
> 人类用户请参考 README.md。

## 给 Agent 的指令

如果你是一个 coding agent（如 Claude Code），请按照以下步骤自动安装 Security Dev Skills：

### 步骤 1：克隆仓库

```bash
git clone git@github.com:P0m32Kun/security-dev-skills.git ~/.claude/skills/security-dev-skills
```

### 步骤 2：进入目录

```bash
cd ~/.claude/skills/security-dev-skills
```

### 步骤 3：运行安装脚本

```bash
./install.sh
```

安装脚本会自动：
- 检查系统环境
- 安装 uv（Python 包管理器）
- 安装 Semble MCP（代码搜索）
- 安装 CodeGraph MCP（代码知识图谱）
- 配置 MCP 服务器到 `~/.claude/settings.json`

### 步骤 4：验证安装

```bash
# 检查 MCP 配置
cat ~/.claude/settings.json | grep -A 3 "mcpServers"

# 应该看到 semble 和 codegraph 的配置
```

### 步骤 5：告知用户

安装完成后，告知用户：

```
Security Dev Skills 安装完成！

已安装：
- Skill 仓库：~/.claude/skills/security-dev-skills
- MCP 服务器：Semble（代码搜索）、CodeGraph（代码知识图谱）

下一步：
1. 重启 Claude Code 以加载 MCP 服务器
2. 阅读 ~/.claude/skills/security-dev-skills/SKILL.md 了解开发流程
3. 开始使用：Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
```

## 安装脚本说明

`install.sh` 支持以下参数：

```bash
./install.sh              # 安装所有依赖
./install.sh --required   # 只安装必需依赖
./install.sh --update     # 更新 skill 仓库
./install.sh --dry-run    # 预览安装内容
./install.sh --help       # 显示帮助
```

## 依赖清单

### 必需依赖

| 类型 | 名称 | 用途 |
|------|------|------|
| MCP | Semble | 快速代码搜索（节省 98% token） |
| MCP | CodeGraph | 代码知识图谱 |
| 工具 | uv | Python 包管理器 |
| 工具 | Git | 版本控制 |

### 可选依赖

| 类型 | 名称 | 用途 |
|------|------|------|
| MCP | Context7 | 实时文档查询 |
| MCP | Playwright | 浏览器自动化 |
| MCP | Agent Browser | AI 浏览器 |
| 工具 | Docker | 容器化 |

## 故障排除

### 问题：git clone 失败

```bash
# 检查 SSH 密钥
ssh -T git@github.com

# 如果没有 SSH 密钥，使用 HTTPS
git clone https://github.com/P0m32Kun/security-dev-skills.git ~/.claude/skills/security-dev-skills
```

### 问题：install.sh 权限不足

```bash
chmod +x install.sh
```

### 问题：uv 安装失败

```bash
# 手动安装 uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 添加到 PATH
export PATH="$HOME/.local/bin:$PATH"
```

### 问题：npm 未安装

```bash
# macOS
brew install node

# Linux
sudo apt-get install nodejs npm
```

## 自动更新

安装完成后，可以设置自动更新：

```bash
# 检查更新
./auto-update.sh --check

# 执行更新
./auto-update.sh

# 设置定时更新（每天凌晨 3 点）
./auto-update.sh --setup-cron
```

## 相关文档

- `SKILL.md` — 体系总览（必读）
- `README.md` — 仓库说明
- `docs/dependencies.md` — 依赖管理详细说明
- `docs/best-practices.md` — 优秀设计模式
