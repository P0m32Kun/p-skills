# 集成 Skills 总览

> 本目录包含与外部 MCP 工具集成的 skills。这些 skills 提供开箱即用的能力，与核心开发流程无缝配合。

## 工具总览

| 工具 | 类型 | 用途 | 必需 |
|------|------|------|------|
| [AgentMemory](https://github.com/rohitg00/agentmemory) | MCP | 持久记忆管理 | 可选 |
| [CodeGraph](https://github.com/colbymchenry/codegraph) | MCP | 代码知识图谱 | 必需 |
| [Semble](https://github.com/MinishLab/semble) | CLI/MCP | 语义代码搜索 | 必需 |

## 使用场景与流程联动

### AgentMemory — 持久记忆管理

AgentMemory 让 agent 拥有跨会话的记忆能力。

#### 使用场景

| 场景 | 触发方式 | 对应 Skill |
|------|---------|-----------|
| 新会话开始，想接续上次工作 | "where were we" | `handoff` |
| 回顾本周做了什么 | "recap this week" | `recap` |
| 保存重要决策到长期记忆 | "remember this" | `remember` |
| 搜索之前遇到的问题 | "recall docker timeout" | `recall` |
| 追溯某行代码的来源 | "why is this code here" | `commit-context` |
| 查看 agent 关联的提交 | "show agent commits" | `commit-history` |
| 删除敏感信息 | "forget this" | `forget` |
| 查看会话历史 | "session history" | `session-history` |

#### 与核心流程的联动

```
Research 阶段
  └─ recall: 搜索之前是否调研过类似方案

Design 阶段
  └─ remember: 保存设计决策
  └─ recall: 查找相关的历史决策

Implement 阶段
  └─ commit-context: 追溯代码来源
  └─ remember: 保存踩坑经验

Retrospective 阶段
  └─ recap: 回顾本次开发的会话
  └─ session-history: 查看详细会话记录
  └─ remember: 保存优化建议

日常使用
  └─ handoff: 恢复上次工作
  └─ forget: 清理过期记忆
```

---

### CodeGraph — 代码知识图谱

CodeGraph 提供结构化的代码分析能力，比 grep 更精准。

#### 使用场景

| 场景 | 触发方式 | 对应工具 |
|------|---------|---------|
| 找到函数定义位置 | "X 定义在哪里" | `codegraph_search` |
| 查看谁调用了某函数 | "谁调用了 Y" | `codegraph_callers` |
| 分析变更影响范围 | "改变 Z 会破坏什么" | `codegraph_impact` |
| 追踪代码执行路径 | "X 如何到达 Y" | `codegraph_trace` |
| 查看符号签名和文档 | "Y 的签名是什么" | `codegraph_node` |
| 获取任务相关的上下文 | — | `codegraph_context` |

#### 与核心流程的联动

```
Research 阶段
  └─ codegraph_search: 快速定位相关代码
  └─ codegraph_impact: 评估变更影响

Design 阶段
  └─ codegraph_context: 获取模块上下文
  └─ codegraph_callers: 分析依赖关系

Implement 阶段
  └─ codegraph_impact: 变更前评估影响
  └─ codegraph_trace: 追踪执行路径

Doc-Sync 阶段
  └─ codegraph_node: 获取最新函数签名
```

#### 经验法则

- 结构性问题用 CodeGraph，字面文本用 grep
- 信任 CodeGraph 结果，不要用 grep 重新验证
- `codegraph_trace` 一次调用返回完整路径，不要手动拼接
- 多符号查看用 `codegraph_expander`，不要循环 `codegraph_node`

---

### Semble — 语义代码搜索

Semble 提供自然语言代码搜索，比 grep 节省 98% token。

#### 使用场景

| 场景 | 触发方式 | 对应工具 |
|------|---------|---------|
| 按意图搜索代码 | "authentication flow" | `semble search` |
| 查找相关实现 | — | `semble find-related` |
| 搜索文档 | — | `semble search --content docs` |
| 探索代码库 | — | `semble search` |

#### 与核心流程的联动

```
Research 阶段
  └─ seemle search: 搜索现有实现和方案

Design 阶段
  └─ seemle search: 了解现有代码结构

Implement 阶段
  └─ seemle find-related: 发现相关实现
  └─ seemle search: 定位需要修改的代码

Doc-Sync 阶段
  └─ seemle search --content docs: 搜索相关文档
```

#### 搜索技巧

- 使用自然语言描述意图，不要写正则
- 优先语义搜索，只对字面匹配用 grep
- 用 `--content docs` 搜索文档，`--content all` 搜索所有内容

---

## 安装与配置

### 必需依赖

```bash
# CodeGraph
npm install -g @colbymchenry/codegraph

# Semble
uv tool install semble
```

### 可选依赖

```bash
# AgentMemory — 参考 GitHub 仓库安装说明
# https://github.com/rohitg00/agentmemory
```

### MCP 配置示例（Claude Code）

```json
{
  "mcpServers": {
    "codegraph": {
      "command": "codegraph",
      "args": ["serve"]
    },
    "semble": {
      "command": "uvx",
      "args": ["--from", "semble[mcp]", "semble"]
    },
    "agentmemory": {
      "command": "npx",
      "args": ["-y", "agentmemory"]
    }
  }
}
```

详见 `../DEPENDENCIES.md`
