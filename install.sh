#!/bin/bash
#
# Security Dev Skills — 安装脚本
#
# 用法：
#   ./install.sh              # 安装 + 配置 agent
#   ./install.sh --agent AGENT # 只配置指定 agent
#   ./install.sh --list-agents # 列出支持的 agent
#   ./install.sh --update     # 更新 skill 仓库
#   ./install.sh --uninstall  # 卸载
#
# 本脚本只负责：
# 1. 克隆/更新仓库
# 2. 创建软链接到各 agent 的 skill 目录
# 3. 更新 agent 配置文件
#
# 依赖检查由 agent 自行完成，参考 DEPENDENCIES.md
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
SKILL_REPO_URL="git@github.com:P0m32Kun/security-dev-skills.git"
SKILL_INSTALL_DIR="$HOME/.security-dev-skills"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# 支持的 Agent 列表
declare -A AGENTS=(
    ["claude-code"]="$HOME/.claude/skills/security-dev-skills"
    ["codex"]="$HOME/.codex/skills/security-dev-skills"
    ["cursor"]="$HOME/.cursor/skills/security-dev-skills"
    ["opencode"]="$HOME/.opencode/skills/security-dev-skills"
    ["windsurf"]="$HOME/.windsurf/skills/security-dev-skills"
    ["aider"]="$HOME/.aider/skills/security-dev-skills"
    ["cline"]="$HOME/.cline/skills/security-dev-skills"
    ["continue"]="$HOME/.continue/skills/security-dev-skills"
    ["generic"]="$HOME/.coding-agent/skills/security-dev-skills"
)

# Agent 配置文件
declare -A AGENT_CONFIGS=(
    ["claude-code"]="$HOME/.claude/CLAUDE.md"
    ["codex"]="$HOME/.codex/AGENTS.md"
    ["cursor"]="$HOME/.cursor/rules"
    ["opencode"]="$HOME/.opencode/AGENTS.md"
    ["windsurf"]="$HOME/.windsurf/rules"
    ["aider"]="$HOME/.aider.conf.yml"
    ["cline"]="$HOME/.cline/rules"
    ["continue"]="$HOME/.continue/config.yaml"
)

# 列出支持的 Agent
list_agents() {
    echo "支持的 Coding Agent："
    echo ""
    echo "  Agent          Skill 目录"
    echo "  ─────────────  ─────────────────────────────────────"
    echo "  claude-code    ~/.claude/skills/security-dev-skills"
    echo "  codex          ~/.codex/skills/security-dev-skills"
    echo "  cursor         ~/.cursor/skills/security-dev-skills"
    echo "  opencode       ~/.opencode/skills/security-dev-skills"
    echo "  windsurf       ~/.windsurf/skills/security-dev-skills"
    echo "  aider          ~/.aider/skills/security-dev-skills"
    echo "  cline          ~/.cline/skills/security-dev-skills"
    echo "  continue       ~/.continue/skills/security-dev-skills"
    echo "  generic        ~/.coding-agent/skills/security-dev-skills"
    echo ""
    echo "使用方式："
    echo "  ./install.sh                    # 安装到所有检测到的 agent"
    echo "  ./install.sh --agent claude-code # 只安装到指定 agent"
}

# 检测已安装的 Agent
detect_agents() {
    local detected=()

    [ -d "$HOME/.claude" ] && detected+=("claude-code")
    [ -d "$HOME/.codex" ] && detected+=("codex")
    [ -d "$HOME/.cursor" ] && detected+=("cursor")
    [ -d "$HOME/.opencode" ] && detected+=("opencode")
    [ -d "$HOME/.windsurf" ] && detected+=("windsurf")
    ([ -f "$HOME/.aider.conf.yml" ] || command -v aider &>/dev/null) && detected+=("aider")
    [ -d "$HOME/.cline" ] && detected+=("cline")
    [ -d "$HOME/.continue" ] && detected+=("continue")

    echo "${detected[@]}"
}

# 创建软链接
create_symlink() {
    local agent=$1
    local target_dir="${AGENTS[$agent]}"

    log_info "配置 $agent..."

    mkdir -p "$(dirname "$target_dir")"

    # 如果已存在软链接
    if [ -L "$target_dir" ]; then
        local current_target=$(readlink "$target_dir")
        if [ "$current_target" = "$SKILL_INSTALL_DIR" ]; then
            log_success "$agent 已配置"
            return 0
        else
            rm "$target_dir"
        fi
    elif [ -d "$target_dir" ]; then
        log_warn "$agent 目录已存在，备份..."
        mv "$target_dir" "${target_dir}.bak.$(date +%Y%m%d%H%M%S)"
    fi

    if ln -s "$SKILL_INSTALL_DIR" "$target_dir"; then
        log_success "$agent: $target_dir -> $SKILL_INSTALL_DIR"
    else
        log_error "$agent 配置失败"
        return 1
    fi
}

# 配置 Agent 的规则文件
configure_agent_rules() {
    local agent=$1
    local config_file="${AGENT_CONFIGS[$agent]}"

    if [ ! -f "$config_file" ]; then
        mkdir -p "$(dirname "$config_file")"
    fi

    # 检查是否已配置
    if [ -f "$config_file" ] && grep -q "security-dev-skills" "$config_file" 2>/dev/null; then
        log_success "$agent 配置文件已包含引用"
        return 0
    fi

    # 添加配置
    case $agent in
        claude-code)
            cat >> "$config_file" << 'EOF'

# Security Dev Skills
@~/.security-dev-skills/SKILL.md
EOF
            ;;
        aider)
            cat >> "$config_file" << 'EOF'

# Security Dev Skills
read:
  - ~/.security-dev-skills/SKILL.md
EOF
            ;;
        *)
            cat >> "$config_file" << 'EOF'

# Security Dev Skills
参考 ~/.security-dev-skills/SKILL.md 中的开发流程。
EOF
            ;;
    esac

    log_success "$agent 配置文件已更新"
}

# 克隆/更新仓库
install_skill_repo() {
    log_info "安装 Security Dev Skills..."

    if [ -d "$SKILL_INSTALL_DIR" ]; then
        log_info "仓库已存在，更新中..."
        cd "$SKILL_INSTALL_DIR"
        git pull
        log_success "更新成功"
    else
        log_info "克隆仓库..."
        mkdir -p "$(dirname "$SKILL_INSTALL_DIR")"
        if git clone "$SKILL_REPO_URL" "$SKILL_INSTALL_DIR"; then
            log_success "克隆成功"
        else
            log_error "克隆失败"
            exit 1
        fi
    fi
}

# 配置 Agent
setup_agents() {
    local target_agent="$1"

    if [ -n "$target_agent" ]; then
        if [ -z "${AGENTS[$target_agent]}" ]; then
            log_error "未知的 agent: $target_agent"
            list_agents
            exit 1
        fi
        create_symlink "$target_agent"
        configure_agent_rules "$target_agent"
    else
        log_info "检测已安装的 Coding Agent..."
        local detected=$(detect_agents)

        if [ -z "$detected" ]; then
            log_warn "未检测到已安装的 Coding Agent"
            log_info "创建通用目录..."
            create_symlink "generic"
        else
            for agent in $detected; do
                create_symlink "$agent"
                configure_agent_rules "$agent"
            done
        fi
    fi
}

# 卸载
uninstall() {
    log_info "卸载 Security Dev Skills..."

    # 删除软链接
    for agent in "${!AGENTS[@]}"; do
        local target_dir="${AGENTS[$agent]}"
        if [ -L "$target_dir" ]; then
            rm "$target_dir"
            log_success "删除 $agent 软链接"
        fi
    done

    # 询问是否删除仓库
    echo ""
    read -p "是否删除仓库目录 $SKILL_INSTALL_DIR? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$SKILL_INSTALL_DIR"
        log_success "仓库已删除"
    else
        log_info "仓库保留：$SKILL_INSTALL_DIR"
    fi

    log_success "卸载完成"
}

# 显示帮助
show_help() {
    cat << EOF
Security Dev Skills — 安装脚本

用法:
    ./install.sh                    安装 + 配置 agent
    ./install.sh --agent AGENT      只配置指定 agent
    ./install.sh --list-agents      列出支持的 agent
    ./install.sh --update           更新 skill 仓库
    ./install.sh --uninstall        卸载
    ./install.sh --help             显示帮助

说明:
    本脚本只负责克隆仓库和创建软链接。
    依赖检查由 agent 自行完成，参考 ~/.security-dev-skills/DEPENDENCIES.md
EOF
}

# 主流程
main() {
    local target_agent=""
    local action="install"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --agent)
                target_agent="$2"
                shift 2
                ;;
            --list-agents)
                list_agents
                exit 0
                ;;
            --update)
                action="update"
                shift
                ;;
            --uninstall)
                action="uninstall"
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

    echo "=========================================="
    echo "  Security Dev Skills — 安装"
    echo "=========================================="
    echo ""

    case $action in
        uninstall)
            uninstall
            exit 0
            ;;
        update)
            install_skill_repo
            exit 0
            ;;
        install)
            install_skill_repo
            echo ""
            setup_agents "$target_agent"
            echo ""

            # 首次安装时检查依赖
            log_info "检查依赖..."
            "$SKILL_INSTALL_DIR/check-deps.sh" --force
            echo ""

            echo "=========================================="
            echo "  安装完成！"
            echo "=========================================="
            echo ""

            log_info "下一步："
            echo "  1. 重启你的 Coding Agent"
            echo "  2. 开始使用：阅读 SKILL.md"
            echo ""

            log_info "依赖说明："
            echo "  依赖状态已缓存，Agent 无需每次检查"
            echo "  更新时会自动重新检查：./install.sh --update"
            echo "  手动检查：./check-deps.sh"
            echo ""
            ;;
    esac
}

main "$@"
