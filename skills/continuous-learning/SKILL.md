---
name: continuous-learning
description: >
  Use when reviewing learned patterns, triggering reflection, or checking skill improvement data.
  Use when user says "学习模式", "learned patterns", "反思", "reflect", "evolve", "查看学习", "learn status".
---

# 持续学习系统

> 从使用经验中提取模式，持续优化 skill 和工作流。

## 核心概念

```
持续学习
├── Observations（观察）— 每次工具调用自动记录
├── Instincts（本能）— 从重复行为中提取的模式
├── Reflections（反思）— 分析观察数据，识别改进点
└── Training（训练）— 将改进应用到 skill 文件
```

数据位置: `~/.p-skills/learning/`

## 快速命令

所有操作通过 `learn` CLI 统一入口：

```bash
learn status              # 查看学习数据概况
learn reflect [project]   # 触发反思，生成 instinct 文件
learn train [project]     # 完整训练循环（需 ≥10 条观察）
learn patterns [project]  # 查看已发现的模式
learn clear [project]     # 清除学习数据
```

如果 `learn` 命令不在 PATH 中，使用完整路径：

```bash
~/.p-skills/bin/learn status
```

省略 `project` 时自动使用最近活跃的项目。

## 触发反思的时机

| 场景 | 命令 | 说明 |
|------|------|------|
| 想知道学到了什么 | `learn status` | 快速查看数据量和已发现模式 |
| 一个功能开发完成后 | `learn reflect` | 从本次工作中提取模式 |
| 积累了多个 session 后 | `learn train` | 完整训练，改进 skill 文件 |
| 好奇当前项目的特点 | `learn patterns` | 查看工具使用、文件类型分布 |

## 数据采集方式

### 有 Hook 的 Agent（Claude Code / Codex / OpenCode / Cursor）

数据采集**自动进行**，通过 hook 在每次工具调用后记录：

| Hook | 记录内容 |
|------|---------|
| PostToolUse | 工具名、文件路径、文件类型、session ID |
| SessionStart | 加载已学习的模式到上下文 |
| Stop | Session 统计汇总 |

无需手动操作，正常使用即可积累数据。

### 无 Hook 的 Agent（其他）

在**每个功能开发完成后**，手动执行反思：

1. 回顾本次 session 做了什么
2. 运行 `learn reflect` 触发分析
3. 或让 agent 在结束前自我总结并写入观察数据

Agent 可以在 session 结束前主动记录：

```bash
# 手动添加一条观察记录
echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'","session_id":"manual","tool":"Edit","file_path":"path/to/file","file_ext":".ts","skill_triggered":"develop-feature","user_reverted":false}' >> ~/.p-skills/learning/projects/<project_id>/observations.jsonl
```

## 训练循环说明

```
Observations (≥10) → Reflect → Propose → Validate → Apply → New Skill Version
```

1. **Reflect** — 分析观察数据，识别高频文件、常用工具、skill 触发模式
2. **Propose** — 基于模式生成 skill 编辑建议
3. **Validate** — 过滤低置信度建议（confidence < 0.5 或 support < 2）
4. **Apply** — 应用通过验证的编辑，自动备份原文件

## 生成的文件

```
~/.p-skills/learning/projects/<id>/
├── observations.jsonl      # 原始观察数据
├── sessions/<session>.json # Session 统计
├── instincts/<pattern>.md  # 生成的本能模式
├── training_state.json     # 训练状态
└── epochs/epoch_N/         # 每轮训练的快照
    ├── reflections.json
    ├── proposals.json
    ├── validation.json
    └── skill_snapshot.md
```

## 隐私与安全

- 所有数据**本地存储**，不上传
- **不记录代码内容** — 只有路径、类型、时间戳
- **不记录对话** — 只有工具使用模式
- 用户可随时 `learn clear` 清除
- 学习数据已在 `.gitignore` 中，不会提交到仓库

## 跨 Agent 兼容性

| Agent | 自动采集 | 机制 | 配置位置 |
|-------|---------|------|---------|
| Claude Code | ✅ | `settings.json` hooks | `~/.claude/settings.json` |
| Codex | ✅ | 内联 TOML `[hooks]` | `~/.codex/config.toml` |
| Cursor | ✅ | `hooks.json`（扁平格式） | `~/.cursor/hooks.json` |
| OpenCode | ✅ | TypeScript plugin | `~/.config/opencode/plugins/p-skills-learning.ts` |
| 其他 | ❌ | 手动触发 | `learn` CLI |

四个 agent 共享同一套学习数据（`~/.p-skills/learning/`）。
即使没有自动采集，`learn reflect` 和 `learn train` 仍然可以基于已有数据工作。
