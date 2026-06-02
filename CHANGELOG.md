# Changelog

本文件记录 Security Dev Skills 的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [0.7.0] - 2026-06-02

### Changed
- 安装脚本重构：支持自动检测 agent 并创建软链接
  - 自动检测已安装的 Coding Agent
  - 创建软链接到各 agent 的 skill 目录
  - 更新 agent 配置文件
  - 支持 `--agent` 参数指定 agent
  - 支持 `--list-agents` 列出支持的 agent
- 更新 README.md 反映新的安装方式

## [0.6.0] - 2026-06-02

### Added
- `INSTALL.md` — 安装说明（供 agent 自动安装使用）
- 支持多种 coding agent：
  - Claude Code（CLAUDE.md）
  - Codex（AGENTS.md）
  - Cursor（.cursorrules）
  - OpenCode（AGENTS.md）
  - Windsurf（.windsurfrules）
  - Aider（.aider.conf.yml）
- 更新 `README.md` 增加两种安装方式：
  - 人类手动安装
  - Agent 自动安装

### Changed
- 优化 README.md 结构，更清晰的安装指引
- 安装目录改为 ~/.security-dev-skills（更通用）

## [0.5.0] - 2026-06-02

### Added
- 外部依赖管理系统
  - `dependencies.yaml` — 依赖清单
  - `install.sh` — 一键安装脚本
  - `auto-update.sh` — 自动更新脚本
  - `docs/dependencies.md` — 依赖管理文档
- 支持的外部依赖：
  - MCP 服务器：Semble, CodeGraph, Context7, Playwright, Agent Browser
  - 工具：uv, Docker, Git
- 自动更新机制：
  - 手动更新：`./auto-update.sh`
  - 定时更新：`./auto-update.sh --setup-cron`
- `docs/best-practices.md` — 优秀 skill 设计模式文档
- 更新 SKILL.md 增加外部依赖章节和设计来源

### Changed
- 移除外部 Skill 依赖，保持仓库独立性
- 将 Semgrep 替换为 Semble（代码搜索工具）
- 明确设计理念：吸收优点，自己实现，不依赖外部 skill

## [0.4.0] - 2026-06-02

### Changed
- 优化 skill 体系，参考优秀 skill 仓库
  - 增加 HARD-GATE 阻断机制
  - 增加 Anti-Patterns 反模式
  - 增加决策树（测试策略）
  - 增加 SMART 验收条件
  - 增加 CONTEXT.md（领域知识）
- 优化 workflow/develop.feature.md
- 优化 testing/strategy.md
- 优化 testing/verify.md
- 优化 docs/sync.md

## [0.3.0] - 2026-06-02

### Added
- 回顾环节 skill：workflow/retrospective.md
  - 收集问题（工具失败、报错、踩坑、skill 评估）
  - 分析根因
  - 量化影响（时间、token）
  - 输出优化建议
- 更新 workflow/develop.feature.md 增加 Retrospective 阶段
- 更新 SKILL.md 增加 retrospective skill 索引
- 参考优秀 skill 仓库：superpowers, gstack, andrej-karpathy-skills, mattpocock/skills

## [0.2.0] - 2026-06-02

### Added
- 完整 skill 体系实现
- 文档 Skill：doc-sync, doc-validate, 文档模板
- 测试 Skill：test-strategy, e2e-write, verify
- 安全 Skill：security-research, poc, tool-integrate
- 发布 Skill：deploy
- 编排器：develop.feature（完整需求开发流程）
- README.md — 仓库说明 + 快速开始
- SKILL.md — 体系总览
- DESIGN.md — 设计文档

## [0.1.0] - 2026-06-02

### Added
- 项目初始化
- 目录结构：workflow/, docs/, testing/, security/, release/
