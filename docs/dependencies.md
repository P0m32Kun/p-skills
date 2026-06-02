# 外部依赖管理

> 本文档说明如何管理 skill 体系的外部依赖。

## 概述

Security Dev Skills 是一个**独立的 skill 仓库**，不依赖外部 skill。只依赖必要的工具和 MCP 服务器。

### 依赖清单

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

## 快速安装

### 一键安装

```bash
# 克隆仓库
git clone git@github.com:P0m32Kun/security-dev-skills.git

# 进入目录
cd security-dev-skills

# 运行安装脚本
./install.sh
```

### 只安装必需依赖

```bash
./install.sh --required
```

### 预览安装内容

```bash
./install.sh --dry-run
```

## 自动更新

### 手动更新

```bash
# 检查更新
./auto-update.sh --check

# 执行更新
./auto-update.sh
```

### 设置定时任务

```bash
# 设置每天凌晨 3 点自动更新
./auto-update.sh --setup-cron

# 移除定时任务
./auto-update.sh --remove-cron
```

### 查看更新日志

```bash
cat ~/.cache/security-dev-skills/update.log
```

## 依赖详情

### Semble（必需）

**用途**：快速代码搜索，比 grep+read 节省 98% token

**安装**：
```bash
uv tool install semble
```

**MCP 配置**：
```json
{
  "command": "uvx",
  "args": ["--from", "semble[mcp]", "semble"]
}
```

**使用**：
```bash
# 搜索代码
semble search "authentication flow" ./my-project
semble search "save_pretrained" ./my-project

# 搜索文档
semble search "deployment guide" ./my-project --content docs
```

**GitHub**：https://github.com/MinishLab/semble

---

### CodeGraph（必需）

**用途**：代码知识图谱，提供符号搜索、调用关系、影响分析

**安装**：
```bash
npm install -g codegraph
```

**MCP 配置**：
```json
{
  "command": "codegraph",
  "args": ["serve"]
}
```

**GitHub**：https://github.com/colbymchenry/codegraph

---

### Context7（可选）

**用途**：实时文档查询，获取最新的库文档

**安装**：
```bash
npm install -g @upstash/context7-mcp
```

**MCP 配置**：
```json
{
  "command": "npx",
  "args": ["-y", "@upstash/context7-mcp"]
}
```

**GitHub**：https://github.com/upstash/context7

---

### Playwright MCP（可选）

**用途**：浏览器自动化，用于 E2E 测试和网页操作

**安装**：
```bash
npm install -g @anthropic-ai/mcp-playwright
```

**MCP 配置**：
```json
{
  "command": "npx",
  "args": ["-y", "@anthropic-ai/mcp-playwright"]
}
```

---

### Agent Browser MCP（可选）

**用途**：AI Agent 浏览器，用于智能网页操作

**安装**：
```bash
npm install -g @anthropic-ai/mcp-browser
```

**MCP 配置**：
```json
{
  "command": "npx",
  "args": ["-y", "@anthropic-ai/mcp-browser"]
}
```

## MCP 配置文件

MCP 服务器配置会自动写入 `~/.claude/settings.json`：

```json
{
  "mcpServers": {
    "semble": {
      "command": "uvx",
      "args": ["--from", "semble[mcp]", "semble"]
    },
    "codegraph": {
      "command": "codegraph",
      "args": ["serve"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

### 手动配置

如果自动配置失败，可以手动编辑：

```bash
vim ~/.claude/settings.json
```

### 查看已配置的 MCP

```bash
claude mcp list
```

## 添加新依赖

### 1. 编辑 dependencies.yaml

```yaml
mcp_servers:
  - name: my-new-mcp
    type: mcp
    description: 我的新 MCP 服务器
    source:
      github: "https://github.com/user/repo"
      npm: "@user/mcp-package"
    install:
      command: "npm"
      args: ["install", "-g", "@user/mcp-package"]
    config:
      command: "npx"
      args: ["-y", "@user/mcp-package"]
    required: false
    tags: [category1, category2]
```

### 2. 更新安装脚本

在 `install.sh` 的 `install_dependencies()` 函数中添加：

```bash
# My New MCP（可选）
if ! $required_only; then
    install_mcp_server "my-new-mcp" \
        "npm" "install" "-g" "@user/mcp-package" \
        "npx" "-y" "@user/mcp-package"
fi
```

### 3. 提交更改

```bash
git add dependencies.yaml install.sh
git commit -m "feat: 添加新依赖 my-new-mcp"
git push
```

用户运行 `./auto-update.sh` 即可自动安装新依赖。

## 故障排除

### MCP 服务器无法启动

```bash
# 检查 MCP 状态
claude mcp list

# 查看 MCP 日志
claude mcp logs semble

# 重新安装
uv tool install semble
```

### uv 安装失败

```bash
# 手动安装 uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 添加到 PATH
export PATH="$HOME/.local/bin:$PATH"
```

### npm 安装失败

```bash
# 检查 npm 版本
npm --version

# 清理缓存
npm cache clean --force

# 重试安装
npm install -g @upstash/context7-mcp
```

### 自动更新失败

```bash
# 查看日志
cat ~/.cache/security-dev-skills/update.log

# 手动更新
cd ~/.claude/skills/security-dev-skills
git pull
./install.sh --required
```

## 参考

- `dependencies.yaml` — 依赖清单
- `install.sh` — 安装脚本
- `auto-update.sh` — 自动更新脚本
- `SKILL.md` — 体系总览
