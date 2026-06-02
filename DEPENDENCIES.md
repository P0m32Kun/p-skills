# 依赖检查清单

> 本文件说明依赖检查机制，**Agent 不需要每次启动都检查依赖**。

## 依赖检查机制

### 缓存机制

依赖检查结果会缓存到 `.deps-status` 文件，有效期 24 小时。

```
首次安装 → 检查依赖 → 写入缓存
    ↓
Agent 启动 → 读取缓存 → 缓存有效 → 跳过检查
    ↓
更新 skill → 检查依赖 → 更新缓存
```

### 何时检查

| 场景 | 是否检查 | 说明 |
|------|---------|------|
| 首次安装 | ✓ | `./install.sh` 自动检查 |
| 更新 skill | ✓ | `./auto-update.sh` 检测到依赖变更时检查 |
| Agent 启动 | ✗ | 读取缓存，不重新检查 |
| 缓存过期（24h） | ✓ | 下次使用时重新检查 |

### 手动检查

```bash
# 查看缓存状态
./check-deps.sh --status

# 强制重新检查
./check-deps.sh --force
```

## Agent 读取缓存

Agent 启动时，读取 `.deps-status` 文件：

```bash
# 检查缓存是否存在
if [ -f ~/.security-dev-skills/.deps-status ]; then
    # 读取缺失的必需依赖
    missing=$(grep "^missing_required=" ~/.security-dev-skills/.deps-status | cut -d= -f2)
    
    if [ -n "$missing" ]; then
        echo "⚠️ 缺少以下依赖："
        # 解析并提示...
    fi
fi
```

## 必需依赖

| 依赖 | 安装方式 | 用途 |
|------|---------|------|
| Git | 系统自带 | 版本控制 |
| uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | Python 包管理 |
| Semble | `uv tool install semble` | 代码搜索 MCP |
| CodeGraph | `npm install -g @colbymchenry/codegraph` | 代码知识图谱 MCP |

## 可选依赖

| 依赖 | 安装方式 | 用途 |
|------|---------|------|
| AgentMemory | 见 GitHub 仓库 | 持久记忆管理 MCP |
| Node.js | https://nodejs.org | 运行部分 MCP |
| Docker | https://docker.com | 容器化（仅部署场景需要） |
| Context7 | `npm install -g @upstash/context7-mcp` | 文档查询 MCP |
| Playwright | `npm install -g @anthropic-ai/mcp-playwright` | 浏览器 MCP |

## 提示用户

如果缓存显示缺失依赖，提示用户：

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

**GitHub**：https://github.com/colbymchenry/codegraph

---

### AgentMemory（可选）

**用途**：持久记忆管理，支持会话历史、知识保存、提交追溯等

**安装**：参考 GitHub 仓库的安装说明

**提供的 Skills**：
- `recall` — 搜索历史观察和学习成果
- `remember` — 保存洞察到长期存储
- `recap` — 总结最近会话
- `handoff` — 恢复上次会话
- `forget` — 删除记忆（隐私保护）
- `commit-context` — 追溯代码到 agent 会话
- `commit-history` — 列出 agent 关联的提交
- `session-history` — 展示会话历史

**GitHub**：https://github.com/rohitg00/agentmemory

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
    },
    "agentmemory": {
      "command": "npx",
      "args": ["-y", "agentmemory"]
    }
  }
}
```

### 其他 Agent

请参考各 agent 的 MCP 配置方式。

### MCP GitHub 地址

| MCP | GitHub |
|-----|--------|
| Semble | https://github.com/MinishLab/semble |
| CodeGraph | https://github.com/colbymchenry/codegraph |
| AgentMemory | https://github.com/rohitg00/agentmemory |

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
