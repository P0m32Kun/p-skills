# 依赖检查清单

> 本文件供 coding agent 使用，在开始工作前检查所需依赖。

## Agent 启动时请检查以下依赖

如果你是一个 coding agent，在使用 Security Dev Skills 之前，请检查以下依赖是否可用。

### 必需依赖

| 依赖 | 检查命令 | 安装方式 | 用途 |
|------|---------|---------|------|
| Git | `git --version` | 系统自带 | 版本控制 |
| uv | `uv --version` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | Python 包管理 |
| Semble | `uv tool list \| grep semble` | `uv tool install semble` | 代码搜索 MCP |
| CodeGraph | `which codegraph` | `npm install -g codegraph` | 代码知识图谱 MCP |

### 可选依赖

| 依赖 | 检查命令 | 安装方式 | 用途 |
|------|---------|---------|------|
| Node.js | `node --version` | https://nodejs.org | 运行部分 MCP |
| npm | `npm --version` | 随 Node.js 安装 | 安装 npm 包 |
| Docker | `docker --version` | https://docker.com | 容器化 |
| Context7 | `npm list -g @upstash/context7-mcp` | `npm install -g @upstash/context7-mcp` | 文档查询 MCP |
| Playwright | `npm list -g @anthropic-ai/mcp-playwright` | `npm install -g @anthropic-ai/mcp-playwright` | 浏览器 MCP |

## 检查流程

Agent 启动时，执行以下检查：

```bash
# 1. 检查必需依赖
check_required() {
    local missing=()

    # Git
    if ! command -v git &>/dev/null; then
        missing+=("Git")
    fi

    # uv
    if ! command -v uv &>/dev/null; then
        missing+=("uv")
    fi

    # Semble
    if ! uv tool list 2>/dev/null | grep -q semble; then
        missing+=("Semble")
    fi

    # CodeGraph
    if ! command -v codegraph &>/dev/null; then
        missing+=("CodeGraph")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo "缺少以下必需依赖："
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        return 1
    fi

    echo "所有必需依赖已安装"
    return 0
}

# 2. 检查可选依赖
check_optional() {
    local missing=()

    # Node.js
    if ! command -v node &>/dev/null; then
        missing+=("Node.js")
    fi

    # Docker
    if ! command -v docker &>/dev/null; then
        missing+=("Docker")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo "以下可选依赖未安装（不影响核心功能）："
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
    fi
}
```

## 提示用户

如果发现缺失依赖，提示用户：

```
⚠️ 缺少以下依赖：

必需：
- Semble: uv tool install semble
- CodeGraph: npm install -g codegraph

可选（不影响核心功能）：
- Docker: https://docker.com

是否现在安装？(y/N)
```

## 依赖说明

### Semble（必需）

**用途**：快速代码搜索，比 grep+read 节省 98% token

**安装**：
```bash
uv tool install semble
```

**验证**：
```bash
uv tool list | grep semble
```

**GitHub**：https://github.com/MinishLab/semble

---

### CodeGraph（必需）

**用途**：代码知识图谱，提供符号搜索、调用关系、影响分析

**安装**：
```bash
npm install -g codegraph
```

**验证**：
```bash
which codegraph
```

**GitHub**：https://github.com/ricocf/codegraph

---

### uv（必需）

**用途**：Python 包管理器，用于安装 Semble

**安装**：
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**验证**：
```bash
uv --version
```

**文档**：https://docs.astral.sh/uv/

---

### Context7（可选）

**用途**：实时文档查询，获取最新的库文档

**安装**：
```bash
npm install -g @upstash/context7-mcp
```

**GitHub**：https://github.com/upstash/context7

---

### Playwright MCP（可选）

**用途**：浏览器自动化，用于 E2E 测试

**安装**：
```bash
npm install -g @anthropic-ai/mcp-playwright
```

## MCP 配置

### Claude Code

MCP 配置文件：`~/.claude/settings.json`

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
    }
  }
}
```

### 其他 Agent

请参考各 agent 的 MCP 配置方式。

## 故障排除

### uv 安装失败

```bash
# 检查网络
curl -I https://astral.sh

# 使用镜像（如需要）
export UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
```

### npm 安装失败

```bash
# 清理缓存
npm cache clean --force

# 使用镜像（如需要）
npm config set registry https://registry.npmmirror.com
```

### Semble 运行失败

```bash
# 重新安装
uv tool uninstall semble
uv tool install semble

# 检查 Python 版本
python3 --version  # 需要 3.10+
```

## 参考

- `SKILL.md` — 体系总览
- `README.md` — 仓库说明
- `install.sh` — 安装脚本
