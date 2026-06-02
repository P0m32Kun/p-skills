#!/bin/bash
#
# Security Dev Skills — 自动更新脚本
#
# 用法：
#   ./auto-update.sh              # 检查并更新
#   ./auto-update.sh --check      # 只检查，不更新
#   ./auto-update.sh --setup-cron # 设置定时任务
#

set -e

# 配置
SKILL_DIR="$HOME/.security-dev-skills"
LOG_FILE="$HOME/.cache/security-dev-skills/update.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 检查更新
check_update() {
    log_info "检查更新..."

    if [ ! -d "$SKILL_DIR" ]; then
        log_error "Skill 仓库未安装"
        return 1
    fi

    cd "$SKILL_DIR"

    # 获取远程更新
    git fetch origin main 2>/dev/null

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)

    if [ "$LOCAL" = "$REMOTE" ]; then
        log_success "已是最新版本"
        echo "up-to-date"
        return 0
    else
        # 计算更新数量
        COMMITS_BEHIND=$(git rev-list HEAD..origin/main --count)
        log_info "有 $COMMITS_BEHIND 个更新可用"
        echo "update-available:$COMMITS_BEHIND"
        return 0
    fi
}

# 执行更新
do_update() {
    log_info "开始更新..."

    if [ ! -d "$SKILL_DIR" ]; then
        log_error "Skill 仓库未安装"
        return 1
    fi

    cd "$SKILL_DIR"

    # 备份当前版本
    CURRENT_VERSION=$(git rev-parse --short HEAD)
    log_info "当前版本: $CURRENT_VERSION"

    # 拉取更新
    if git pull origin main; then
        NEW_VERSION=$(git rev-parse --short HEAD)
        log_success "更新成功: $CURRENT_VERSION -> $NEW_VERSION"

        # 检查是否有新的依赖
        if git diff "$CURRENT_VERSION" HEAD --name-only | grep -q "DEPENDENCIES.md\|check-deps.sh"; then
            log_info "检测到依赖变更，重新检查依赖..."
            ./check-deps.sh --force
        fi

        # 显示更新日志
        log_info "更新内容："
        git log "$CURRENT_VERSION"..HEAD --oneline

        return 0
    else
        log_error "更新失败"
        return 1
    fi
}

# 设置定时任务
setup_cron() {
    log_info "设置定时任务..."

    # 获取脚本路径
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/auto-update.sh"

    # 创建 cron 条目（每天凌晨 3 点检查更新）
    CRON_ENTRY="0 3 * * * $SCRIPT_PATH >> $LOG_FILE 2>&1"

    # 检查是否已存在
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        log_warn "定时任务已存在"
    else
        # 添加定时任务
        (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
        log_success "定时任务已设置（每天凌晨 3 点）"
    fi

    # 显示当前定时任务
    log_info "当前定时任务："
    crontab -l 2>/dev/null | grep -E "security-dev-skills|auto-update" || echo "无"
}

# 移除定时任务
remove_cron() {
    log_info "移除定时任务..."

    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/auto-update.sh"

    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -
        log_success "定时任务已移除"
    else
        log_warn "定时任务不存在"
    fi
}

# 显示帮助
show_help() {
    cat << EOF
Security Dev Skills — 自动更新脚本

用法:
    ./auto-update.sh              检查并更新
    ./auto-update.sh --check      只检查，不更新
    ./auto-update.sh --setup-cron 设置定时任务（每天凌晨 3 点）
    ./auto-update.sh --remove-cron 移除定时任务
    ./auto-update.sh --help       显示帮助

日志文件: $LOG_FILE
EOF
}

# 主流程
main() {
    local action="update"

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check)
                action="check"
                shift
                ;;
            --setup-cron)
                action="setup-cron"
                shift
                ;;
            --remove-cron)
                action="remove-cron"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done

    case $action in
        check)
            check_update
            ;;
        update)
            STATUS=$(check_update)
            if [[ "$STATUS" == update-available:* ]]; then
                do_update
            fi
            ;;
        setup-cron)
            setup_cron
            ;;
        remove-cron)
            remove_cron
            ;;
    esac
}

main "$@"
