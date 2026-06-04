# P-Skills — OpenCode Installation

> 本文件是 OpenCode 安装入口。告诉 OpenCode 读取本文件并按指引完成安装。

## 给 OpenCode 的指令

请执行以下步骤：

### 1. 克隆仓库

```bash
git clone https://github.com/P0m32Kun/p-skills.git ~/.p-skills
cd ~/.p-skills
```

### 2. 加载 Bootstrap

将以下内容追加到项目的 `AGENTS.md`（项目级）或 `~/.opencode/AGENTS.md`（全局）：

```markdown
# P Skills

参考 ~/.p-skills/skills/bootstrap/SKILL.md 中的开发流程。

## 核心开发流程

Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective

每个阶段有明确的完成标准，不能跳过。

## Skill 索引

所有 skill 在 `~/.p-skills/skills/` 下：

- 会话入口：`bootstrap/`
- 需求开发：`develop-feature/`
- Bug 修复：`fix-bug/`
- 设计讨论：`brainstorming/`
- 实施计划：`writing-plans/`
- TDD：`tdd/`
- 测试策略：`test-strategy/`
- E2E 测试：`e2e-write/`
- 用户验证：`verify/`
- 文档同步：`doc-sync/`
- 文档校验：`doc-validate/`
- 发布部署：`deploy/`
- 回顾：`retrospective/`
- 安全调研：`security-research/`
- PoC 编写：`security-poc/`
- 安全集成：`security-integrate/`
- Subagent 编排：`subagent-driven-development/`、`dispatching-parallel-agents/`
- 元技能（写 skill）：`writing-skills/`
```

### 3. 告知用户

```
P Skills 已安装到 ~/.p-skills

下一步：
1. 重启 OpenCode 加载配置
2. 阅读 ~/.p-skills/skills/bootstrap/SKILL.md 了解触发机制
3. 试着说"帮我修复这个 bug"验证是否自动触发 fix-bug skill
```

## 验证安装

安装后发送以下消息验证触发：

> 我要上线一个新的用户注册模块，整个流程你帮我走一遍。

预期：OpenCode 自动加载 `develop-feature` skill 并按 Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective 流程推进。

## 更新

```bash
cd ~/.p-skills && git pull --rebase
```

## 相关文档

- `~/.p-skills/SKILL.md` — 体系总览
- `~/.p-skills/INSTALL.md` — 多 agent 安装说明
- `~/.p-skills/DEPENDENCIES.md` — 依赖清单
