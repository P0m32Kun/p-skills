#!/bin/bash
#
# Security Dev Skills — 依赖检查脚本
#
# 用法：
#   ./check-deps.sh          # 检查依赖并更新缓存
#   ./check-deps.sh --force  # 强制重新检查
#   ./check-deps.sh --status # 显示缓存状态
#
# 检查结果缓存到 .deps-status 文件
# Agent 启动时读取缓存，只在缓存不存在或过期时重新检查
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_STATUS_FILE="$SCRIPT_DIR/.deps-status"
DEPS_CACHE_TTL=86400  # 缓存有效期：24 小时

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# 检查依赖
check_dependency() {
    local cmd=$1
    if command -v "$cmd" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 检查所有依赖
check_all_deps() {
    local missing_required=()
    local missing_optional=()
    local installed=()

    # 必需依赖
    # Git
    if check_dependency git; then
        installed+=("git")
    else
        missing_required+=("git")
    fi

    # uv
    if check_dependency uv; then
        installed+=("uv")
    else
        missing_required+=("uv")
    fi

    # Semble
    if uv tool list 2>/dev/null | grep -q semble; then
        installed+=("semble")
    else
        missing_required+=("semble")
    fi

    # CodeGraph
    if check_dependency codegraph; then
        installed+=("codegraph")
    else
        missing_required+=("codegraph")
    fi

    # 可选依赖
    # Node.js
    if check_dependency node; then
        installed+=("node")
    else
        missing_optional+=("node")
    fi

    # Docker
    if check_dependency docker; then
        installed+=("docker")
    else
        missing_optional+=("docker")
    fi

    # Context7
    if npm list -g @upstash/context7-mcp &>/dev/null; then
        installed+=("context7")
    else
        missing_optional+=("context7")
    fi

    # Playwright
    if npm list -g @anthropic-ai/mcp-playwright &>/dev/null; then
        installed+=("playwright")
    else
        missing_optional+=("playwright")
    fi

    # 输出结果
    echo "installed=$(IFS=,; echo "${installed[*]}")"
    echo "missing_required=$(IFS=,; echo "${missing_required[*]}")"
    echo "missing_optional=$(IFS=,; echo "${missing_optional[*]}")"
    echo "timestamp=$(date +%s)"
}

# 写入缓存
write_cache() {
    local status="$1"
    echo "$status" > "$DEPS_STATUS_FILE"
}

# 读取缓存
read_cache() {
    if [ -f "$DEPS_STATUS_FILE" ]; then
        cat "$DEPS_STATUS_FILE"
    fi
}

# 检查缓存是否有效
is_cache_valid() {
    if [ ! -f "$DEPS_STATUS_FILE" ]; then
        return 1
    fi

    local cache_timestamp=$(grep "^timestamp=" "$DEPS_STATUS_FILE" | cut -d= -f2)
    local current_timestamp=$(date +%s)
    local age=$((current_timestamp - cache_timestamp))

    if [ $age -gt $DEPS_CACHE_TTL ]; then
        return 1
    fi

    return 0
}

# 显示状态
show_status() {
    if [ ! -f "$DEPS_STATUS_FILE" ]; then
        log_warn "缓存不存在，请先运行 check-deps.sh"
        exit 1
    fi

    echo "依赖状态缓存："
    echo ""

    local installed=$(grep "^installed=" "$DEPS_STATUS_FILE" | cut -d= -f2)
    local missing_required=$(grep "^missing_required=" "$DEPS_STATUS_FILE" | cut -d= -f2)
    local missing_optional=$(grep "^missing_optional=" "$DEPS_STATUS_FILE" | cut -d= -f2)
    local timestamp=$(grep "^timestamp=" "$DEPS_STATUS_FILE" | cut -d= -f2)

    # 计算缓存时间
    local current_timestamp=$(date +%s)
    local age=$((current_timestamp - timestamp))
    local hours=$((age / 3600))

    echo "缓存时间: ${hours}小时前"
    echo ""

    if [ -n "$installed" ]; then
        echo -e "${GREEN}已安装:${NC}"
        IFS=',' read -ra arr <<< "$installed"
        for dep in "${arr[@]}"; do
            echo "  ✓ $dep"
        done
    fi

    if [ -n "$missing_required" ]; then
        echo ""
        echo -e "${RED}缺少必需依赖:${NC}"
        IFS=',' read -ra arr <<< "$missing_required"
        for dep in "${arr[@]}"; do
            echo "  ✗ $dep"
        done
    fi

    if [ -n "$missing_optional" ]; then
        echo ""
        echo -e "${YELLOW}缺少可选依赖:${NC}"
        IFS=',' read -ra arr <<< "$missing_optional"
        for dep in "${arr[@]}"; do
            echo "  - $dep"
        done
    fi
}

# 主流程
main() {
    local force=false
    local status_only=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force=true
                shift
                ;;
            --status)
                status_only=true
                shift
                ;;
            --help|-h)
                echo "用法: ./check-deps.sh [--force] [--status]"
                echo ""
                echo "选项:"
                echo "  --force   强制重新检查"
                echo "  --status  显示缓存状态"
                exit 0
                ;;
            *)
                echo "未知参数: $1"
                exit 1
                ;;
        esac
    done

    # 只显示状态
    if $status_only; then
        show_status
        exit 0
    fi

    # 检查缓存是否有效
    if ! $force && is_cache_valid; then
        log_info "缓存有效，跳过检查"
        show_status
        exit 0
    fi

    log_info "检查依赖..."

    # 检查所有依赖
    local status=$(check_all_deps)

    # 写入缓存
    write_cache "$status"

    # 显示结果
    show_status

    # 检查是否有缺失的必需依赖
    local missing_required=$(echo "$status" | grep "^missing_required=" | cut -d= -f2)
    if [ -n "$missing_required" ]; then
        echo ""
        log_error "缺少必需依赖，请手动安装："
        IFS=',' read -ra arr <<< "$missing_required"
        for dep in "${arr[@]}"; do
            case $dep in
                uv)
                    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
                    ;;
                semble)
                    echo "  uv tool install semble"
                    ;;
                codegraph)
                    echo "  npm install -g codegraph"
                    ;;
                git)
                    echo "  请安装 Git: https://git-scm.com"
                    ;;
            esac
        done
        exit 1
    fi

    log_success "所有必需依赖已安装"
    exit 0
}

main "$@"
