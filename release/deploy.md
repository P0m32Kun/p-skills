---
name: deploy
description: 发布部署流程（支持容器化、npm、Python、二进制等场景）
version: 1.1.0
tags: [release, deploy, docker, npm, pypi, ci]
triggers:
  - "发布部署"
  - "版本发布"
  - "Docker 镜像"
  - "npm publish"
  - "pip publish"
inputs:
  - name: version_type
    description: 版本类型（PATCH/MINOR/MAJOR）
    required: true
  - name: release_notes
    description: 发布说明
    required: false
outputs:
  - name: release_artifact
    description: 发布产物（Docker 镜像/Git tag）
---

# 发布部署流程

## 前置条件
- 所有测试通过（Implement 阶段完成）
- 文档已同步（Doc-Sync 阶段完成）
- 用户验证通过（Verify 阶段完成）
- 代码已合并到主分支

## 项目类型

根据项目类型选择发布场景：

```
项目类型？
├── 容器化应用（Web 服务、API）→ Docker 发布
├── npm 包（前端库、CLI 工具）→ npm publish
├── Python 包（库、CLI 工具）→ PyPI 发布
├── 二进制程序（Go/Rust CLI）→ Binary 发布
└── 其他 → 通用 Git tag 流程
```

以下按场景分别说明。

## 流程

### 场景 A：容器化应用发布

适用于 Web 服务、API 等容器化项目。

#### 1. 版本号确定

遵循 [语义化版本](https://semver.org/lang/zh-CN/)：

| 版本类型 | 何时使用 | 示例 |
|---------|---------|------|
| MAJOR | 不兼容的 API 变更 | 1.0.0 → 2.0.0 |
| MINOR | 向后兼容的功能新增 | 1.0.0 → 1.1.0 |
| PATCH | 向后兼容的问题修复 | 1.0.0 → 1.0.1 |

#### 获取当前版本

```bash
# 从 Git tag 获取
git describe --tags --abbrev=0

# 从 package.json 获取
jq -r '.version' package.json

# 从 Cargo.toml 获取
grep '^version' Cargo.toml | head -1 | cut -d'"' -f2
```

#### 计算新版本

```bash
CURRENT_VERSION="1.2.3"
VERSION_TYPE="MINOR"  # PATCH, MINOR, MAJOR

# 拆分版本号
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# 根据类型递增
case $VERSION_TYPE in
  PATCH) PATCH=$((PATCH + 1)) ;;
  MINOR) MINOR=$((MINOR + 1)); PATCH=0 ;;
  MAJOR) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "New version: $NEW_VERSION"
```

### 2. Docker 镜像构建

#### Dockerfile 最佳实践

```dockerfile
# 多阶段构建
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# 最终镜像
FROM alpine:3.18

RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/main .
COPY --from=builder /app/config ./config

EXPOSE 8080
CMD ["./main"]
```

#### 构建命令

```bash
# 构建镜像
docker build -t myapp:${NEW_VERSION} .
docker build -t myapp:latest .

# 测试镜像
docker run --rm myapp:${NEW_VERSION} --version
```

### 3. 推送到 ACR

#### Azure Container Registry

```bash
# 登录 ACR
az acr login --name myregistry

# 打标签
docker tag myapp:${NEW_VERSION} myregistry.azurecr.io/myapp:${NEW_VERSION}
docker tag myapp:${NEW_VERSION} myregistry.azurecr.io/myapp:latest

# 推送
docker push myregistry.azurecr.io/myapp:${NEW_VERSION}
docker push myregistry.azurecr.io/myapp:latest
```

#### GitHub Container Registry

```bash
# 登录 GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 打标签
docker tag myapp:${NEW_VERSION} ghcr.io/USERNAME/myapp:${NEW_VERSION}
docker tag myapp:${NEW_VERSION} ghcr.io/USERNAME/myapp:latest

# 推送
docker push ghcr.io/USERNAME/myapp:${NEW_VERSION}
docker push ghcr.io/USERNAME/myapp:latest
```

### 4. 更新 CHANGELOG

```markdown
# Changelog

## [1.3.0] - 2026-06-02

### Added
- 新增用户认证模块
- 新增 API 限流功能

### Changed
- 优化数据库查询性能

### Fixed
- 修复登录超时问题

## [1.2.3] - 2026-05-28

### Fixed
- 修复配置文件加载错误
```

#### 自动生成 CHANGELOG

```bash
# 使用 conventional-changelog
npx conventional-changelog -p angular -i CHANGELOG.md -s

# 或使用 git log
git log --oneline --no-merges v1.2.3..HEAD
```

### 5. 创建 Git tag + GitHub Release

```bash
# 创建 Git tag
git tag -a v${NEW_VERSION} -m "Release v${NEW_VERSION}"
git push origin v${NEW_VERSION}

# 创建 GitHub Release
gh release create v${NEW_VERSION} \
  --title "Release v${NEW_VERSION}" \
  --notes-file RELEASE_NOTES.md \
  --draft=false \
  --prerelease=false
```

#### GitHub Actions 自动化

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to ACR
        uses: azure/docker-login@v1
        with:
          login-server: myregistry.azurecr.io
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}
      
      - name: Extract version
        id: version
        run: echo "version=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          push: true
          tags: |
            myregistry.azurecr.io/myapp:${{ steps.version.outputs.version }}
            myregistry.azurecr.io/myapp:latest
      
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
```

---

## 场景 B：npm 包发布

适用于前端库、Node.js CLI 工具、npm 包。

### 发布流程

```bash
# 1. 更新版本号
npm version patch  # 或 minor, major

# 2. 构建
npm run build

# 3. 登录（首次）
npm login

# 4. 发布
npm publish

# 5. 推送 tag
git push --follow-tags
```

### package.json 配置

```json
{
  "name": "@scope/package-name",
  "version": "1.0.0",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "files": ["dist"],
  "scripts": {
    "build": "tsc",
    "prepublishOnly": "npm run build"
  }
}
```

### GitHub Actions 自动化

```yaml
# .github/workflows/npm-publish.yml
name: npm Publish

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 20
          registry-url: https://registry.npmjs.org
      - run: npm ci
      - run: npm run build
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

---

## 场景 C：Python 包发布

适用于 Python 库、CLI 工具。

### 发布流程

```bash
# 1. 更新版本号（pyproject.toml）
# 手动修改或使用 bump2version

# 2. 构建
uv build
# 或
python -m build

# 3. 发布到 PyPI
uv publish
# 或
twine upload dist/*

# 4. 推送 tag
git push --follow-tags
```

### pyproject.toml 配置

```toml
[project]
name = "package-name"
version = "1.0.0"
description = "包描述"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### GitHub Actions 自动化

```yaml
# .github/workflows/pypi-publish.yml
name: PyPI Publish

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install build twine
      - run: python -m build
      - run: twine upload dist/*
        env:
          TWINE_USERNAME: __token__
          TWINE_PASSWORD: ${{ secrets.PYPI_TOKEN }}
```

---

## 场景 D：二进制发布

适用于 Go、Rust 编写的 CLI 工具。

### Go 二进制

```bash
# 1. 构建多平台
GOOS=linux GOARCH=amd64 go build -o myapp-linux-amd64 .
GOOS=darwin GOARCH=arm64 go build -o myapp-darwin-arm64 .
GOOS=windows GOARCH=amd64 go build -o myapp-windows-amd64.exe .

# 2. 创建 GitHub Release 并上传
gh release create v1.0.0 \
  myapp-linux-amd64 \
  myapp-darwin-arm64 \
  myapp-windows-amd64.exe \
  --title "Release v1.0.0" \
  --generate-notes
```

### GoReleaser（推荐）

```yaml
# .goreleaser.yml
version: 2
builds:
  - env: [CGO_ENABLED=0]
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]
archives:
  - format: tar.gz
    name_template: "{{ .ProjectName }}_{{ .Os }}_{{ .Arch }}"
```

```bash
# 安装
go install github.com/goreleaser/goreleaser@latest

# 发布
goreleaser release --clean
```

### GitHub Actions 自动化

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - uses: actions/setup-go@v5
        with:
          go-version: stable
      - uses: goreleaser/goreleaser-action@v6
        with:
          version: latest
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 场景 E：通用 Git tag 流程

适用于不走上述特定流程的项目。

```bash
# 1. 更新版本号（按项目约定）
# 2. 更新 CHANGELOG
# 3. 提交
git add -A && git commit -m "release: v1.0.0"

# 4. 创建 tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 5. 创建 GitHub Release
gh release create v1.0.0 --generate-notes
```

## 完成标准
- [ ] 版本号已确定（遵循语义化版本）
- [ ] 发布产物已构建并测试
- [ ] 发布产物已推送到目标平台（ACR/npm/PyPI/GitHub Release）
- [ ] CHANGELOG 已更新
- [ ] Git tag 已创建
- [ ] GitHub Release 已创建

## 参考
- `workflow/develop.feature.md` — 完整需求开发流程
- [语义化版本](https://semver.org/lang/zh-CN/)
- [Docker 最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [GitHub Actions](https://docs.github.com/en/actions)
