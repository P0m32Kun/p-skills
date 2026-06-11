---
name: github-flow
description: >
  End-to-end GitHub workflow using gh CLI. Covers reading issues, creating
  branches, implementing changes, committing, creating PRs, and linking issues.
  Use when user says "做这个 issue", "实现 #123", "提个 PR", "create PR",
  "github flow", "从 issue 开始", "fix #456".
---

# GitHub Flow — Issue to PR 全流程

## Overview

使用 `gh` CLI 实现从 Issue 到 PR 的完整工作流。每个 Issue 自动创建分支、关联提交、产出 PR。

## Prerequisites

- `gh` CLI 已安装且已认证 (`gh auth status`)
- 项目是一个 git 仓库
- 远程仓库已配置 (`gh repo view` 能正常工作)

## 流程总览

```
Read Issue → Create Branch → Implement → Commit → Push → Create PR → Link Issue
```

---

## Step 1: 读取 Issue

```bash
# 读取单个 issue 详情
gh issue view <number>

# 读取 issue 并获取 JSON 格式（便于解析）
gh issue view <number> --json title,body,labels,assignees,state

# 列出未关闭的 issue
gh issue list --state open --limit 20
```

从 Issue 中提取：
- **标题**：简述需求
- **描述**：详细需求、验收标准
- **标签**：优先级、类型（bug/feature/enhancement）
- **指派人**：确认是否分配给自己
- **关联 PR**：是否已有相关 PR

## Step 2: 创建分支

分支命名规范：
```
feature/<issue-number>-<brief-description>
fix/<issue-number>-<brief-description>
chore/<issue-number>-<brief-description>
```

```bash
# 确保 main/master 是最新的
git checkout main && git pull

# 创建并切换到新分支
git checkout -b feature/123-add-user-auth

# 或者用 gh 创建分支（会自动关联 issue）
gh issue develop <number> --checkout
```

## Step 3: 实现代码

在分支上进行开发。这个阶段使用正常的开发流程：
- 编写代码
- 运行测试
- 本地验证

## Step 4: 提交代码

提交信息格式：
```
<type>(<scope>): <description>

<body>

Fixes #<issue-number>
```

类型（type）：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响逻辑）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具/CI

```bash
# 添加变更
git add .

# 提交（包含 issue 关联）
git commit -m "feat(auth): add user authentication

- Implement JWT token generation
- Add login/logout endpoints
- Add auth middleware

Fixes #123"

# 或者分步提交
git add src/auth/
git commit -m "feat(auth): add JWT token generation

Fixes #123"
```

**关键**：在提交信息中写 `Fixes #123` 或 `Closes #123`，PR 合并后会自动关闭 Issue。

## Step 5: 推送分支

```bash
git push origin feature/123-add-user-auth

# 或者设置上游分支
git push -u origin feature/123-add-user-auth
```

## Step 6: 创建 PR

```bash
# 使用 gh 创建 PR（自动关联 issue）
gh pr create \
  --title "feat(auth): add user authentication" \
  --body "## What

Implement user authentication with JWT tokens.

## Changes
- Add JWT token generation and validation
- Add login/logout API endpoints
- Add auth middleware for protected routes
- Add unit tests for auth module

## Testing
- [x] Unit tests pass
- [x] Manual testing with Postman
- [ ] Integration tests (TODO)

## Related
Fixes #123

## Screenshots (if UI changes)
N/A" \
  --base main \
  --head feature/123-add-user-auth \
  --reviewer "@me" \
  --label "feature,auth"
```

### 简化方式

```bash
# 最简方式：gh 会交互式询问
gh pr create

# 自动填充方式：使用 commit 信息作为 PR 描述
gh pr create --fill

# 指定 reviewers
gh pr create --reviewer user1,user2

# 指定 labels
gh pr create --label "feature,priority:high"

# 指定 assignees
gh pr create --assignee "@me"

# 创建 draft PR
gh pr create --draft
```

### PR 描述模板

项目可以定义 PR 模板 (`.github/pull_request_template.md`)，gh 会自动使用。

## Step 7: 关联 Issue

如果提交信息中已包含 `Fixes #<number>`，PR 创建后会自动关联。

手动关联方式：
```bash
# 在 PR 描述中引用
Fixes #123
Closes #123
Resolves #123

# 或者通过 gh 关联
gh pr edit <pr-number> --add-label "fixes-issue-123"
```

## 完整工作流示例

```bash
# 1. 查看 issue
gh issue view 123

# 2. 创建分支
gh issue develop 123 --checkout

# 3. 开发（这里由 agent 实现代码）
# ... 编写代码 ...

# 4. 运行测试验证
npm test

# 5. 提交
git add .
git commit -m "feat(auth): add user authentication

Implement JWT-based auth with login/logout endpoints.

Fixes #123"

# 6. 推送
git push -u origin feature/123-add-user-auth

# 7. 创建 PR
gh pr create --fill --reviewer "@me"
```

## 常用 gh 命令速查

### Issue 操作
```bash
gh issue view <number>                    # 查看 issue
gh issue list --state open                # 列出未关闭 issue
gh issue create                           # 创建新 issue
gh issue close <number>                   # 关闭 issue
gh issue reopen <number>                  # 重新打开 issue
gh issue comment <number> --body "text"   # 添加评论
gh issue edit <number> --add-label "bug"  # 添加标签
gh issue develop <number> --checkout      # 创建关联分支并切换
```

### PR 操作
```bash
gh pr create                              # 创建 PR（交互式）
gh pr create --fill                       # 自动填充 PR 描述
gh pr view <number>                       # 查看 PR
gh pr list                                # 列出 PR
gh pr checks <number>                     # 查看 CI 状态
gh pr merge <number>                      # 合并 PR
gh pr diff <number>                       # 查看 PR diff
gh pr edit <number> --add-reviewer "user" # 添加 reviewer
gh pr comment <number> --body "text"      # 添加评论
```

### 仓库操作
```bash
gh repo view                              # 查看当前仓库信息
gh repo clone <owner/repo>                # 克隆仓库
gh api repos/:owner/:repo                 # 调用 GitHub API
```

## 错误处理

| 错误 | 原因 | 解决 |
|------|------|------|
| `gh: not authenticated` | 未登录 | `gh auth login` |
| `gh: not a git repository` | 不在 git 仓库中 | `cd` 到项目目录 |
| `gh: could not determine base branch` | 无法确定基础分支 | `gh pr create --base main` |
| `gh: no commits between base and head` | 没有新提交 | 确保有新的 commit |
| `GraphQL error: Field 'reviewers' doesn't exist` | reviewer 名称错误 | 使用 `@me` 或正确的用户名 |

## Best Practices

1. **每个 Issue 一个分支** — 不要在同一个分支做多个不相关的 Issue
2. **提交信息要规范** — 使用 conventional commits 格式
3. **PR 描述要详细** — 包含 What/Why/Testing/Related
4. **关联 Issue** — 始终使用 `Fixes #<number>` 关联
5. **小 PR 优先** — 一个 PR 只做一件事，便于 review
6. **Draft PR** — 未完成的工作用 draft PR
7. **Labels** — 使用标签分类 PR（feature/bug/docs/chore）

## 与其他 Skill 配合

- `code-review` — PR 创建后自动触发代码审查
- `fix-bug` — 修复 Issue 时使用标准化流程
- `develop-feature` — 开发新功能时使用完整流程
- `tdd` — 测试驱动开发
- `deploy` — PR 合并后触发部署
