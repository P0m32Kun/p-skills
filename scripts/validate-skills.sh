#!/bin/bash
#
# Skill 文件校验脚本
#
# 检查所有 .md 文件的 frontmatter 是否包含必填字段
# 用法：./scripts/validate-skills.sh
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# 排除的目录（不需要 frontmatter 校验）
EXCLUDE_DIRS="docs/templates integrations"

# 排除的文件（不需要 frontmatter）
EXCLUDE_FILES="README.md CHANGELOG.md CONTEXT.md DESIGN.md DEPENDENCIES.md INSTALL.md best-practices.md dependencies.md analysis.md"

# 必填字段
REQUIRED_FIELDS="name description version"

errors=0
checked=0

log_error() { echo -e "${RED}✗${NC} $1"; }
log_ok() { echo -e "${GREEN}✓${NC} $1"; }
log_skip() { echo -e "${YELLOW}⏭${NC} $1"; }

# 检查单个文件的 frontmatter
validate_file() {
    local file="$1"
    local rel_path="${file#$REPO_ROOT/}"

    # 检查是否在排除列表中
    local basename=$(basename "$file")
    local rel_dir=$(dirname "${file#$REPO_ROOT/}")
    for exclude in $EXCLUDE_FILES; do
        if [ "$basename" = "$exclude" ]; then
            log_skip "$rel_path (排除)"
            return 0
        fi
    done
    for exclude_dir in $EXCLUDE_DIRS; do
        if [ "$rel_dir" = "$exclude_dir" ] || [[ "$rel_dir" == "$exclude_dir"/* ]]; then
            log_skip "$rel_path (排除目录)"
            return 0
        fi
    done

    # 检查是否有 frontmatter（以 --- 开头）
    local first_line=$(head -1 "$file")
    if [ "$first_line" != "---" ]; then
        log_error "$rel_path: 缺少 frontmatter（文件不以 --- 开头）"
        errors=$((errors + 1))
        return 1
    fi

    # 提取 frontmatter（两个 --- 之间的内容）
    local frontmatter=$(awk '/^---$/{n++; next} n==1{print}' "$file")

    if [ -z "$frontmatter" ]; then
        log_error "$rel_path: frontmatter 为空"
        errors=$((errors + 1))
        return 1
    fi

    # 检查必填字段
    local file_ok=true
    for field in $REQUIRED_FIELDS; do
        if ! echo "$frontmatter" | grep -q "^${field}:"; then
            log_error "$rel_path: 缺少必填字段 '$field'"
            errors=$((errors + 1))
            file_ok=false
        fi
    done

    if $file_ok; then
        log_ok "$rel_path"
    fi

    checked=$((checked + 1))
}

# 检查链接有效性（可选，需要 markdown-link-check）
check_links() {
    local file="$1"
    if command -v markdown-link-check &>/dev/null; then
        markdown-link-check "$file" --quiet 2>/dev/null || true
    fi
}

echo "=========================================="
echo "  Skill 文件校验"
echo "=========================================="
echo ""

# 查找所有 .md 文件
find "$REPO_ROOT" -name "*.md" -not -path "*/.git/*" -not -path "*/node_modules/*" | sort | while read -r file; do
    validate_file "$file"
done

echo ""
echo "=========================================="
if [ $errors -eq 0 ]; then
    echo -e "  ${GREEN}校验通过${NC}：$checked 个文件"
else
    echo -e "  ${RED}校验失败${NC}：$errors 个错误"
fi
echo "=========================================="

exit $errors
