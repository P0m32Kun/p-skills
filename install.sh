#!/bin/bash
#
# Security Dev Skills — 安装脚本
#
# 用法：
#   ./install.sh              # 安装所有依赖 + 配置 agent
#   ./install.sh --required   # 只安装必需依赖
#   ./install.sh --agent AGENT # 只配置指定 agent
#   ./install.sh --list-agents # 列出支持的 agent
#   ./install.sh --update     # 更新 skill 仓库
#   ./install.sh --dry-run    # 预览安装内容
#
# 依赖清单：dependencies.yaml
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPENDENCIES_FILE="$SCRIPT_DIR/dependencies.yaml"
SKILL_REPO_URL="git@github.com:P0m32Kun/security-dev-skills.git"
SKILL_INSTALL_DIR="$HOME/.security-dev-skills"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 检查依赖
check_dependency() {
    local cmd=$1
    if command -v "$cmd" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 支持的 Agent 列表
declare -A AGENTS=(
    # Claude Code
    ["claude-code"]="$HOME/.claude/skills/security-dev-skills"

    # Codex (OpenAI)
    ["codex"]="$HOME/.codex/skills/security-dev-skills"

    # Cursor
    ["cursor"]="$HOME/.cursor/skills/security-dev-skills"

    # OpenCode
    ["opencode"]="$HOME/.opencode/skills/security-dev-skills"

    # Windsurf
    ["windsurf"]="$HOME/.windsurf/skills/security-dev-skills"

    # Aider
    ["aider"]="$HOME/.aider/skills/security-dev-skills"

    # Cline
    ["cline"]="$HOME/.cline/skills/security-dev-skills"

    # Continue
    ["continue"]="$HOME/.continue/skills/security-dev-skills"

    # Generic (通用目录)
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

    # Claude Code
    if [ -d "$HOME/.claude" ]; then
        detected+=("claude-code")
    fi

    # Codex
    if [ -d "$HOME/.codex" ]; then
        detected+=("codex")
    fi

    # Cursor
    if [ -d "$HOME/.cursor" ]; then
        detected+=("cursor")
    fi

    # OpenCode
    if [ -d "$HOME/.opencode" ]; then
        detected+=("opencode")
    fi

    # Windsurf
    if [ -d "$HOME/.windsurf" ]; then
        detected+=("windsurf")
    fi

    # Aider
    if [ -f "$HOME/.aider.conf.yml" ] || command -v aider &> /dev/null; then
        detected+=("aider")
    fi

    # Cline (VS Code extension)
    if [ -d "$HOME/.cline" ] || [ -d "$HOME/.vscode/extensions" ]; then
        detected+=("cline")
    fi

    # Continue
    if [ -d "$HOME/.continue" ]; then
        detected+=("continue")
    fi

    echo "${detected[@]}"
}

# 创建软链接
create_symlink() {
    local agent=$1
    local target_dir="${AGENTS[$agent]}"

    log_info "配置 $agent..."

    # 创建目标目录
    mkdir -p "$(dirname "$target_dir")"

    # 如果已存在软链接，检查是否指向正确位置
    if [ -L "$target_dir" ]; then
        local current_target=$(readlink "$target_dir")
        if [ "$current_target" = "$SKILL_INSTALL_DIR" ]; then
            log_success "$agent 已配置（软链接正确）"
            return 0
        else
            log_warn "$agent 软链接指向错误位置，重新创建..."
            rm "$target_dir"
        fi
    elif [ -d "$target_dir" ]; then
        log_warn "$agent 目录已存在（非软链接），备份后重新创建..."
        mv "$target_dir" "${target_dir}.bak.$(date +%Y%m%d%H%M%S)"
    fi

    # 创建软链接
    if ln -s "$SKILL_INSTALL_DIR" "$target_dir"; then
        log_success "$agent 配置成功：$target_dir -> $SKILL_INSTALL_DIR"
    else
        log_error "$agent 配置失败"
        return 1
    fi
}

# 配置 Agent 的规则文件
configure_agent_rules() {
    local agent=$1
    local config_file="${AGENT_CONFIGS[$agent]}"

    # 检查配置文件是否存在
    if [ ! -f "$config_file" ]; then
        log_info "创建 $agent 配置文件：$config_file"
        mkdir -p "$(dirname "$config_file")"
    fi

    # 检查是否已包含 security-dev-skills 引用
    if [ -f "$config_file" ] && grep -q "security-dev-skills" "$config_file" 2>/dev/null; then
        log_success "$agent 配置文件已包含 security-dev-skills 引用"
        return 0
    fi

    # 根据 agent 类型添加配置
    case $agent in
        claude-code)
            cat >> "$config_file" << 'EOF'

# Security Dev Skills
# 开发流程：Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
@~/.security-dev-skills/SKILL.md
EOF
            ;;
        codex|opencode)
            cat >> "$config_file" << 'EOF'

# Security Dev Skills
参考 ~/.security-dev-skills/SKILL.md 中的开发流程。
开发流程：Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
EOF
            ;;
        cursor)
            cat >> "$config_file" << 'EOF'

# Security Dev Skills
参考 ~/.security-dev-skills/SKILL.md 中的开发流程。
开发流程：Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
EOF
            ;;
        windsurf)
            cat >> "$config_file" << 'EOF'

# Security Dev Skills
参考 ~/.security-dev-skills/SKILL.md 中的开发流程。
开发流程：Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
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
开发流程：Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective
EOF
            ;;
    esac

    log_success "$agent 配置文件已更新：$config_file"
}

# 检查系统环境
check_system() {
    log_info "检查系统环境..."

    # 检查操作系统
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_success "操作系统: macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_success "操作系统: Linux"
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi

    # 检查 Git
    if check_dependency git; then
        GIT_VERSION=$(git --version)
        log_success "Git: $GIT_VERSION"
    else
        log_error "Git 未安装，这是必需依赖"
        exit 1
    fi

    # 检查 Node.js
    if check_dependency node; then
        NODE_VERSION=$(node --version)
        log_success "Node.js: $NODE_VERSION"
    else
        log_warn "Node.js 未安装，部分 MCP 服务器需要 Node.js"
    fi

    # 检查 Python
    if check_dependency python3; then
        PYTHON_VERSION=$(python3 --version)
        log_success "Python: $PYTHON_VERSION"
    else
        log_warn "Python 未安装，部分工具需要 Python"
    fi

    # 检查 uv
    if check_dependency uv; then
        UV_VERSION=$(uv --version)
        log_success "uv: $UV_VERSION"
    else
        log_warn "uv 未安装，将尝试安装"
        install_uv
    fi
}

# 安装 uv
install_uv() {
    log_info "安装 uv..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        export PATH="$HOME/.local/bin:$PATH"
        log_success "uv 安装成功"
    else
        log_error "uv 安装失败"
        log_warn "请手动安装: https://docs.astral.sh/uv/getting-started/installation/"
    fi
}

# 安装 MCP 服务器到 Claude Code
install_mcp_claude() {
    local name=$1
    local command=$2
    shift 2
    local args=("$@")

    log_info "配置 MCP 服务器: $name (Claude Code)"

    local config_file="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"

    if [ ! -f "$config_file" ]; then
        echo '{"mcpServers":{}}' > "$config_file"
    fi

    python3 << EOF
import json

config_file = "$config_file"
name = "$name"
command = "$command"
args = [$(printf '"%s",' "${args[@]}" | sed 's/,$//')]

try:
    with open(config_file, 'r') as f:
        config = json.load(f)
except:
    config = {"mcpServers": {}}

if "mcpServers" not in config:
    config["mcpServers"] = {}

config["mcpServers"][name] = {
    "command": command,
    "args": args
}

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print(f"MCP 服务器 {name} 配置成功")
EOF
}

# 安装依赖
install_dependencies() {
    log_info "安装依赖..."

    # 安装 uv
    if ! check_dependency uv; then
        install_uv
    fi

    # 安装 Semble
    log_info "安装 Semble..."
    if uv tool install semble 2>/dev/null; then
        log_success "Semble 安装成功"
    else
        log_warn "Semble 安装失败，请手动安装：uv tool install semble"
    fi

    # 安装 CodeGraph
    log_info "安装 CodeGraph..."
    if check_dependency npm; then
        if npm install -g codegraph 2>/dev/null; then
            log_success "CodeGraph 安装成功"
        else
            log_warn "CodeGraph 安装失败，请手动安装：npm install -g codegraph"
        fi
    else
        log_warn "npm 未安装，跳过 CodeGraph 安装"
    fi

    # 配置 Claude Code MCP
    log_info "配置 Claude Code MCP..."
    install_mcp_claude "semble" "uvx" "--from" "semble[mcp]" "semble"
    install_mcp_claude "codegraph" "codegraph" "serve"
}

# 安装 skill 仓库
install_skill_repo() {
    log_info "安装 Security Dev Skills..."

    # 如果已存在，更新
    if [ -d "$SKILL_INSTALL_DIR" ]; then
        log_info "Skill 仓库已存在，更新中..."
        cd "$SKILL_INSTALL_DIR"
        git pull
        log_success "Skill 仓库更新成功"
        return 0
    fi

    # 克隆仓库
    log_info "克隆 Skill 仓库..."
    mkdir -p "$(dirname "$SKILL_INSTALL_DIR")"
    if git clone "$SKILL_REPO_URL" "$SKILL_INSTALL_DIR"; then
        log_success "Skill 仓库安装成功"
    else
        log_error "Skill 仓库安装失败"
        return 1
    fi
}

# 配置 Agent
setup_agents() {
    local target_agent="$1"

    if [ -n "$target_agent" ]; then
        # 只配置指定的 agent
        if [ -z "${AGENTS[$target_agent]}" ]; then
            log_error "未知的 agent: $target_agent"
            list_agents
            exit 1
        fi
        create_symlink "$target_agent"
        configure_agent_rules "$target_agent"
    else
        # 配置所有检测到的 agent
        log_info "检测已安装的 Coding Agent..."
        local detected=$(detect_agents)

        if [ -z "$detected" ]; then
            log_warn "未检测到已安装的 Coding Agent"
            log_info "将创建通用目录：~/.coding-agent/skills/security-dev-skills"
            create_symlink "generic"
        else
            for agent in $detected; do
                create_symlink "$agent"
                configure_agent_rules "$agent"
            done
        fi
    fi
}

# 更新 skill 仓库
update_skill_repo() {
    log_info "更新 Security Dev Skills..."

    if [ ! -d "$SKILL_INSTALL_DIR" ]; then
        log_error "Skill 仓库未安装"
        return 1
    fi

    cd "$SKILL_INSTALL_DIR"

    # 检查是否有更新
    git fetch
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        log_success "Skill 仓库已是最新版本"
        return 0
    fi

    # 拉取更新
    if git pull; then
        log_success "Skill 仓库更新成功"

        # 重新安装依赖（如有新增）
        log_info "检查依赖更新..."
        install_dependencies
    else
        log_error "Skill 仓库更新失败"
        return 1
    fi
}

# 显示帮助
show_help() {
    cat << EOF
Security Dev Skills — 安装脚本

用法:
    ./install.sh                    安装所有依赖 + 配置 agent
    ./install.sh --required         只安装必需依赖
    ./install.sh --agent AGENT      只配置指定 agent
    ./install.sh --list-agents      列出支持的 agent
    ./install.sh --update           更新 skill 仓库
    ./install.sh --dry-run          预览安装内容
    ./install.sh --help             显示帮助

示例:
    ./install.sh                          # 完整安装
    ./install.sh --agent claude-code      # 只配置 Claude Code
    ./install.sh --agent cursor           # 只配置 Cursor
    ./install.sh --list-agents            # 查看支持的 agent

依赖清单: dependencies.yaml
EOF
}

# 主安装流程
main() {
    local required_only=false
    local target_agent=""
    local update_only=false
    local dry_run=false
    local list_agents_only=false

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --required)
                required_only=true
                shift
                ;;
            --agent)
                target_agent="$2"
                shift 2
                ;;
            --list-agents)
                list_agents_only=true
                shift
                ;;
            --update)
                update_only=true
                shift
                ;;
            --dry-run)
                dry_run=true
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

    # 列出支持的 agent
    if $list_agents_only; then
        list_agents
        exit 0
    fi

    echo "=========================================="
    echo "  Security Dev Skills — 安装"
    echo "=========================================="
    echo ""

    # 检查系统环境
    check_system

    echo ""

    # 如果只是更新
    if $update_only; then
        update_skill_repo
        exit 0
    fi

    # 安装 skill 仓库
    install_skill_repo

    echo ""

    # 安装依赖
    if ! $required_only; then
        install_dependencies
    fi

    echo ""

    # 配置 Agent
    log_info "配置 Coding Agent..."
    setup_agents "$target_agent"

    echo ""
    echo "=========================================="
    echo "  安装完成！"
    echo "=========================================="
    echo ""

    # 显示安装摘要
    log_info "安装摘要："
    echo "  - Skill 仓库: $SKILL_INSTALL_DIR"
    echo ""

    # 显示配置的 agent
    log_info "已配置的 Agent："
    if [ -n "$target_agent" ]; then
        echo "  - $target_agent: ${AGENTS[$target_agent]}"
    else
        local detected=$(detect_agents)
        if [ -n "$detected" ]; then
            for agent in $detected; do
                echo "  - $agent: ${AGENTS[$agent]}"
            done
        else
            echo "  - generic: ~/.coding-agent/skills/security-dev-skills"
        fi
    fi
    echo ""

    log_info "下一步："
    echo "  1. 重启你的 Coding Agent"
    echo "  2. 阅读 SKILL.md 了解开发流程"
    echo "  3. 开始使用：Research → Design → Implement → Doc-Sync → Verify → Release"
    echo ""
}

# 运行主流程
main "$@"
