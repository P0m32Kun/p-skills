# P-Skills 重构方案

## 问题

当前结构下，只有根目录的 `dev-workflow/SKILL.md` 能被 pi 发现，其他 skill 都在子目录中无法触发。

## 设计来源

- [mattpocock/skills](https://github.com/mattpocock/skills) — 扁平结构、link-skills.sh 安装、description 作为触发条件
- [obra/superpowers](https://github.com/obra/superpowers) — bootstrap skill、HARD-GATE 阻断、强制 skill 检查

## 新结构

```
~/.p-skills/
├── skills/                        ← 所有可触发的 skill（扁平）
│   ├── bootstrap/                 ← 会话入口，强制检查 skill
│   │   └── SKILL.md
│   ├── brainstorming/             ← 需求讨论与设计探索
│   │   └── SKILL.md
│   ├── writing-plans/             ← 实施计划编写
│   │   └── SKILL.md
│   ├── develop-feature/           ← 完整需求开发编排器
│   │   └── SKILL.md
│   ├── fix-bug/                   ← 标准化 Bug 修复
│   │   └── SKILL.md
│   ├── tdd/                       ← 测试驱动开发
│   │   └── SKILL.md
│   ├── test-strategy/             ← 测试策略选择
│   │   └── SKILL.md
│   ├── verify/                    ← 用户视角验证
│   │   └── SKILL.md
│   ├── e2e-write/                 ← E2E 测试编写
│   │   └── SKILL.md
│   ├── doc-sync/                  ← 文档同步
│   │   └── SKILL.md
│   ├── doc-validate/              ← 文档一致性校验
│   │   └── SKILL.md
│   ├── deploy/                    ← 发布部署
│   │   └── SKILL.md
│   ├── retrospective/             ← 开发回顾与优化
│   │   └── SKILL.md
│   ├── security-research/         ← 安全工具/方案调研
│   │   └── SKILL.md
│   ├── security-poc/              ← PoC 编写与验证
│   │   └── SKILL.md
│   └── security-integrate/        ← 安全工具集成
│       └── SKILL.md
├── scripts/
│   ├── link-skills.sh             ← 安装脚本（创建 symlink）
│   └── list-skills.sh             ← 列出所有 skill
├── integrations/                  ← 外部集成（保持不变）
├── docs/                          ← 参考文档
├── CONTEXT.md                     ← 项目上下文
├── README.md
└── CHANGELOG.md
```

## 安装机制

```bash
# link-skills.sh
find "$REPO/skills" -name SKILL.md | while read skill_md; do
  src="$(dirname "$skill_md")"
  name="$(basename "$src")"
  ln -sfn "$src" "$HOME/.pi/agent/skills/$name"
done
```

## Frontmatter 格式

```yaml
---
name: skill-name
description: >
  Use when X, Y, Z. Use when user says "A", "B", "C".
---
```

只保留 `name` 和 `description`，移除 `version`, `tags`, `triggers`, `inputs`, `outputs`。
