---
name: deploy
description: >
  Use when deploying, releasing, publishing packages, or creating releases.
  Use when user says "发布部署", "版本发布", "Docker 镜像", "npm publish",
  "pip publish", "deploy", "release".
---

# 发布部署流程

## Overview

支持容器化（Docker）、npm、Python、二进制等场景的发布流程。可重复、可回滚、尽量自动化。

## When to Use

- 发布新版本（Docker 镜像、npm 包、pip 包、二进制）
- 创建 Git tag 和 GitHub Release
- 部署到生产环境

**何时不用**：
- 只是开发阶段，还没到发布环节
- 只需要跑测试 → 用 `verify`

> 支持容器化、npm、Python、二进制等场景的发布流程。

## 前置条件

- 所有测试通过
- 文档已同步
- 代码已审查

## 核心原则

1. **可重复** — 发布流程可重复执行
2. **可回滚** — 发布失败可以回滚
3. **自动化** — 尽可能自动化

## 项目类型

| 类型 | 特征 | 发布方式 |
|------|------|---------|
| 容器化应用 | Dockerfile | Docker 镜像 |
| npm 包 | package.json | npm publish |
| Python 包 | pyproject.toml | pip publish |
| 二进制 | Go/Rust | GitHub Release |
| Web 应用 | 静态文件 | CDN/服务器 |

## 流程

### 场景 A：容器化应用发布

#### 1. 版本号确定

```bash
# 获取当前版本
git describe --tags --abbrev=0

# 计算新版本
# PATCH: 修复 bug
# MINOR: 新功能
# MAJOR: 破坏性变更
```

#### 2. Docker 镜像构建

```dockerfile
# Dockerfile 最佳实践
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

```bash
# 构建命令
docker build -t myapp:1.0.0 .
docker tag myapp:1.0.0 myapp:latest
```

#### 3. 推送到 ACR

```bash
# Azure Container Registry
az acr login --name myregistry
docker tag myapp:1.0.0 myregistry.azurecr.io/myapp:1.0.0
docker push myregistry.azurecr.io/myapp:1.0.0

# GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
docker tag myapp:1.0.0 ghcr.io/username/myapp:1.0.0
docker push ghcr.io/username/myapp:1.0.0
```

#### 4. 更新 CHANGELOG

```markdown
# Changelog

## [1.0.0] - YYYY-MM-DD

### Added
- 用户注册功能
- 用户登录功能

### Fixed
- 修复登录超时问题

### Changed
- 优化数据库查询
```

#### 5. 创建 Git tag + GitHub Release

```bash
# 创建 tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# GitHub CLI 创建 Release
gh release create v1.0.0 \
  --title "Release v1.0.0" \
  --generate-notes
```

#### GitHub Actions 自动化

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t myapp:${{ github.ref_name }} .

      - name: Login to GHCR
        run: echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin

      - name: Push to GHCR
        run: |
          docker tag myapp:${{ github.ref_name }} ghcr.io/${{ github.repository }}:${{ github.ref_name }}
          docker push ghcr.io/${{ github.repository }}:${{ github.ref_name }}

      - name: Create Release
        run: gh release create ${{ github.ref_name }} --generate-notes
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 场景 B：npm 包发布

#### 发布流程

```bash
# 更新版本
npm version patch  # 或 minor, major

# 构建
npm run build

# 测试
npm test

# 发布
npm publish

# 推送 tag
git push --follow-tags
```

#### package.json 配置

```json
{
  "name": "my-package",
  "version": "1.0.0",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "files": ["dist"],
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "prepublishOnly": "npm run build && npm test"
  }
}
```

### 场景 C：Python 包发布

#### 发布流程

```bash
# 更新版本
# 在 pyproject.toml 或 setup.py 中更新版本号

# 构建
python -m build

# 测试
pytest

# 发布
twine check dist/*
twine upload dist/*
```

#### pyproject.toml 配置

```toml
[project]
name = "my-package"
version = "1.0.0"
description = "My package description"
readme = "README.md"
license = {text = "MIT"}
requires-python = ">=3.8"

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"
```

### 场景 D：二进制发布

#### Go 二进制

```bash
# 构建
CGO_ENABLED=0 go build -o myapp ./cmd/myapp

# 交叉编译
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o myapp-linux-amd64 ./cmd/myapp
GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build -o myapp-darwin-arm64 ./cmd/myapp
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -o myapp-windows-amd64.exe ./cmd/myapp
```

#### GoReleaser（推荐）

```yaml
# .goreleaser.yml
project_name: myapp
builds:
  - env:
      - CGO_ENABLED=0
    goos:
      - linux
      - darwin
      - windows
    goarch:
      - amd64
      - arm64
archives:
  - format: tar.gz
    name_template: "{{ .ProjectName }}_{{ .Version }}_{{ .Os }}_{{ .Arch }}"
checksum:
  name_template: 'checksums.txt'
changelog:
  sort: asc
```

### 场景 E：通用 Git tag 流程

```bash
# 1. 更新版本号
# 2. 更新 CHANGELOG
# 3. 提交变更
git add .
git commit -m "chore: release v1.0.0"

# 4. 创建 tag
git tag -a v1.0.0 -m "Release v1.0.0"

# 5. 推送
git push origin main --follow-tags

# 6. 创建 GitHub Release
gh release create v1.0.0 --generate-notes
```

## 完成标准

- [ ] 版本号已确定
- [ ] 构建成功
- [ ] 测试通过
- [ ] 已推送到仓库/镜像仓库
- [ ] CHANGELOG 已更新
- [ ] Git tag 已创建
- [ ] GitHub Release 已创建

## Red Flags — STOP

当你有以下任何想法时，**停下来重新检查**：

- "先推上去看看"
- "本地测过了就行"
- "这次改很小，不用走完整流程"
- "忘了更新 CHANGELOG"
- "tag 晚点再打"
- "手动推镜像就行"

**所有这些都意味着你正在合理化跳过流程。回到 deploy 的第一步。**

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "小改动不用正式 release" | 小改动也可能破坏生产 |
| "CI 会帮我检查" | CI 不检查版本号、CHANGELOG、tag |
| "回滚很容易" | 没回滚计划的发布就是赌博 |
| "只是内部工具" | 内部工具也有用户 |
| "文档晚点补" | 晚点 = 永远不 |

## 参考

- `skills/develop-feature/` — 完整开发流程
- [Semantic Versioning](https://semver.org/) — 语义化版本
- [Keep a Changelog](https://keepachangelog.com/) — CHANGELOG 规范
- [GoReleaser](https://goreleaser.com/) — Go 发布工具
