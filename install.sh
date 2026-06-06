#!/bin/bash
#
# P Skills — 安装脚本
#
# 用法：
#   ./install.sh              # 安装 + 配置 agent
#   ./install.sh --agent AGENT # 只配置指定 agent
#   ./install.sh --list-agents # 列出支持的 agent
#   ./install.sh --update     # 更新 skill 仓库
#   ./install.sh --uninstall  # 卸载
#
# 兼容 Bash 3.2+（macOS 默认版本）
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
SKILL_REPO_URL="git@github.com:P0m32Kun/p-skills.git"
SKILL_INSTALL_DIR="$HOME/.p-skills"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# 获取 agent 的 skill 目录
get_agent_skill_dir() {
    local agent=$1
    case $agent in
        claude-code) echo "$HOME/.claude/skills/p-skills" ;;
        codex)       echo "$HOME/.codex/skills/p-skills" ;;
        cursor)      echo "$HOME/.cursor/skills/p-skills" ;;
        windsurf)    echo "$HOME/.windsurf/skills/p-skills" ;;
        aider)       echo "$HOME/.aider/skills/p-skills" ;;
        cline)       echo "$HOME/.cline/skills/p-skills" ;;
        continue)    echo "$HOME/.continue/skills/p-skills" ;;
        pi)          echo "$HOME/.pi/agent/skills/p-skills" ;;
        reasonix)    echo "$HOME/.reasonix/skills" ;;
        generic)     echo "$HOME/.coding-agent/skills/p-skills" ;;
        *)           echo "" ;;
    esac
}

# 获取 agent 的配置文件
get_agent_config_file() {
    local agent=$1
    case $agent in
        claude-code) echo "$HOME/.claude/CLAUDE.md" ;;
        codex)       echo "$HOME/.codex/AGENTS.md" ;;
        cursor)      echo "$HOME/.cursor/rules/p-skills.mdc" ;;
        opencode)    echo "$HOME/.config/opencode/AGENTS.md" ;;
        windsurf)    echo "$HOME/.windsurf/rules" ;;
        aider)       echo "$HOME/.aider.conf.yml" ;;
        cline)       echo "$HOME/.cline/rules" ;;
        continue)    echo "$HOME/.continue/config.yaml" ;;
        pi)          echo "$HOME/.pi/agent/instructions.md" ;;
        *)           echo "" ;;
    esac
}

# 列出支持的 Agent
list_agents() {
    echo "支持的 Coding Agent："
    echo ""
    echo "  Agent          Skill 目录"
    echo "  ─────────────  ─────────────────────────────────────"
    echo "  claude-code    ~/.claude/skills/p-skills"
    echo "  codex          ~/.codex/skills/p-skills"
    echo "  cursor         ~/.cursor/skills/p-skills"
    echo "  opencode       ~/.config/opencode/plugins/ (plugin)"
    echo "  windsurf       ~/.windsurf/skills/p-skills"
    echo "  aider          ~/.aider/skills/p-skills"
    echo "  cline          ~/.cline/skills/p-skills"
    echo "  continue       ~/.continue/skills/p-skills"
    echo "  pi             ~/.pi/agent/skills/p-skills"
    echo "  reasonix       ~/.reasonix/skills"
    echo "  generic        ~/.coding-agent/skills/p-skills"
    echo ""
    echo "使用方式："
    echo "  ./install.sh                    # 安装到所有检测到的 agent"
    echo "  ./install.sh --agent claude-code # 只安装到指定 agent"
}

# 检测已安装的 Agent
detect_agents() {
    local detected=""

    [ -d "$HOME/.claude" ] && detected="$detected claude-code"
    [ -d "$HOME/.codex" ] && detected="$detected codex"
    [ -d "$HOME/.cursor" ] && detected="$detected cursor"
    [ -d "$HOME/.opencode" ] && detected="$detected opencode"
    [ -d "$HOME/.windsurf" ] && detected="$detected windsurf"
    ([ -f "$HOME/.aider.conf.yml" ] || command -v aider &>/dev/null) && detected="$detected aider"
    [ -d "$HOME/.cline" ] && detected="$detected cline"
    [ -d "$HOME/.continue" ] && detected="$detected continue"
    [ -d "$HOME/.pi" ] && detected="$detected pi"
    [ -d "$HOME/.reasonix" ] && detected="$detected reasonix"

    echo "$detected"
}

# 创建软链接（扁平化：每个 skill 单独一条链接，便于 agent 自动发现）
#
# Agent 通常只在 skill 根目录下按 "<name>/SKILL.md" 一层扫描，
# 不会递归到 <repo>/skills/<name>/SKILL.md。所以把每个 skill 目录
# 单独链接到 agent 的 skill 根目录下：
#   <agent_skill_dir>/fix-bug        → ~/.p-skills/skills/fix-bug
#   <agent_skill_dir>/brainstorming  → ~/.p-skills/skills/brainstorming
#   ...
create_symlink() {
    local agent=$1
    local skill_root=$(get_agent_skill_dir "$agent")

    if [ -z "$skill_root" ]; then
        # Agent 不使用 skill 目录（如 OpenCode 使用 plugin）
        return 0
    fi

    log_info "配置 $agent（扁平化链接到 $skill_root）..."

    mkdir -p "$skill_root"

    # 向后兼容：清理旧版聚合软链 <skill_root>/p-skills → ~/.p-skills
    local old_aggregate="$skill_root/p-skills"
    if [ -L "$old_aggregate" ]; then
        local old_target
        old_target=$(readlink "$old_aggregate")
        if [ "$old_target" = "$SKILL_INSTALL_DIR" ]; then
            rm "$old_aggregate"
            log_info "清理旧版聚合链接：$old_aggregate"
        fi
    fi

    local skills_src="$SKILL_INSTALL_DIR/skills"
    if [ ! -d "$skills_src" ]; then
        log_error "找不到 skills 源目录：$skills_src"
        return 1
    fi

    local linked=0
    local skipped=0
    for skill_dir in "$skills_src"/*/; do
        [ -d "$skill_dir" ] || continue
        [ -f "$skill_dir/SKILL.md" ] || continue

        local name
        name=$(basename "$skill_dir")
        local target="$skill_root/$name"

        if [ -L "$target" ]; then
            local cur
            cur=$(readlink "$target")
            if [ "$cur" = "$skill_dir" ]; then
                skipped=$((skipped + 1))
                continue
            fi
            # 指向别处：覆盖
            ln -sfn "$skill_dir" "$target"
        elif [ -e "$target" ]; then
            log_warn "$agent: $target 已存在且不是软链，替换为软链"
            rm -rf "$target"
        else
            ln -s "$skill_dir" "$target"
        fi
        linked=$((linked + 1))
    done

    # 链接 bin 目录（learn CLI 等工具）
    local bin_target="$skill_root/bin"
    if [ -L "$bin_target" ]; then
        local cur
        cur=$(readlink "$bin_target")
        if [ "$cur" != "$SKILL_INSTALL_DIR/bin" ]; then
            ln -sfn "$SKILL_INSTALL_DIR/bin" "$bin_target"
        fi
    elif [ ! -e "$bin_target" ]; then
        ln -s "$SKILL_INSTALL_DIR/bin" "$bin_target"
    fi

    log_success "$agent: 新建 $linked 条链接（$skipped 条已存在）"
}

# 配置 Agent 的规则文件
configure_agent_rules() {
    local agent=$1
    local config_file=$(get_agent_config_file "$agent")

    if [ -z "$config_file" ]; then
        return 0
    fi

    # 确保目录存在
    mkdir -p "$(dirname "$config_file")"

    # 检查是否已配置
    if [ -f "$config_file" ] && grep -q "p-skills" "$config_file" 2>/dev/null; then
        log_success "$agent 配置文件已包含引用"
        return 0
    fi

    # 添加配置
    case $agent in
        reasonix)
            # Reasonix 自动发现 ~/.reasonix/skills/<name>/SKILL.md，无需配置文件
            log_success "$agent 已配置（自动发现，无需配置文件）"
            return 0
            ;;
        claude-code)
            cat >> "$config_file" << 'EOF'

# P Skills
@~/.p-skills/SKILL.md
EOF
            ;;
        cursor)
            # Cursor 使用 .mdc 格式
            cat > "$config_file" << 'EOF'
---
description: P Skills - 标准化开发流程
globs:
---

# P Skills

参考 ~/.p-skills/SKILL.md 中的开发流程。

## 开发流程

Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective

每个阶段有明确的完成标准，不能跳过。

## 核心 Skill

- 完整需求开发：~/.p-skills/skills/develop-feature/SKILL.md
- Bug 修复：~/.p-skills/skills/fix-bug/SKILL.md
- 回顾：~/.p-skills/skills/retrospective/SKILL.md
- 文档同步：~/.p-skills/skills/doc-sync/SKILL.md
- 测试策略：~/.p-skills/skills/test-strategy/SKILL.md
- 功能验证：~/.p-skills/skills/verify/SKILL.md
EOF
            ;;
        aider)
            cat >> "$config_file" << 'EOF'

# P Skills
read:
  - ~/.p-skills/SKILL.md
EOF
            ;;
        pi)
            # Pi 使用 instructions.md
            cat >> "$config_file" << 'EOF'

# P Skills

参考 ~/.p-skills/SKILL.md 中的开发流程。

## 开发流程

Research → Design → Implement → Doc-Sync → Verify → Release → Retrospective

每个阶段有明确的完成标准，不能跳过。

## 核心 Skill

- 完整需求开发：~/.p-skills/skills/develop-feature/SKILL.md
- Bug 修复：~/.p-skills/skills/fix-bug/SKILL.md
- 回顾：~/.p-skills/skills/retrospective/SKILL.md
- 文档同步：~/.p-skills/skills/doc-sync/SKILL.md
- 测试策略：~/.p-skills/skills/test-strategy/SKILL.md
- 功能验证：~/.p-skills/skills/verify/SKILL.md
EOF
            ;;
        *)
            cat >> "$config_file" << 'EOF'

# P Skills
参考 ~/.p-skills/SKILL.md 中的开发流程。
EOF
            ;;
    esac

    log_success "$agent 配置文件已更新"
}

# 克隆/更新仓库
install_skill_repo() {
    log_info "安装 P Skills..."

    if [ -d "$SKILL_INSTALL_DIR" ]; then
        log_info "仓库已存在，更新中..."
        cd "$SKILL_INSTALL_DIR"
        git pull --rebase --autostash
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
        local target_dir=$(get_agent_skill_dir "$target_agent")
        if [ -z "$target_dir" ]; then
            log_error "未知的 agent: $target_agent"
            list_agents
            exit 1
        fi
        create_symlink "$target_agent"
        configure_agent_rules "$target_agent"
    else
        log_info "检测已安装的 Coding Agent..."
        local detected=$(detect_agents)

        if [ -z "$(echo $detected | tr -d ' ')" ]; then
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
    log_info "卸载 P Skills..."

    # 遍历所有已知 agent，删除扁平化 skill 链接 + 旧版聚合链接
    for agent in claude-code codex cursor opencode windsurf aider cline continue pi reasonix generic; do
        local skill_root
        skill_root=$(get_agent_skill_dir "$agent")
        [ -n "$skill_root" ] || continue
        [ -d "$skill_root" ] || continue

        # 删除指向本仓库的扁平 skill 链接
        for entry in "$skill_root"/*; do
            [ -L "$entry" ] || continue
            local target
            target=$(readlink "$entry")
            if [ "$target" = "$SKILL_INSTALL_DIR/skills/$(basename "$entry")" ] \
                || [[ "$target" == "$SKILL_INSTALL_DIR/skills/"* ]]; then
                rm "$entry"
                log_success "删除 $agent: $entry"
            fi
        done

        # 删除 bin 链接
        local bin_link="$skill_root/bin"
        if [ -L "$bin_link" ]; then
            local bin_target
            bin_target=$(readlink "$bin_link")
            if [ "$bin_target" = "$SKILL_INSTALL_DIR/bin" ]; then
                rm "$bin_link"
                log_success "删除 $agent: $bin_link"
            fi
        fi

        # 删除旧版聚合链接 <skill_root>/p-skills → ~/.p-skills
        local old_aggregate="$skill_root/p-skills"
        if [ -L "$old_aggregate" ]; then
            local old_target
            old_target=$(readlink "$old_aggregate")
            if [ "$old_target" = "$SKILL_INSTALL_DIR" ]; then
                rm "$old_aggregate"
                log_success "删除 $agent 旧版聚合链接：$old_aggregate"
            fi
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
P Skills — 安装脚本

用法:
    ./install.sh                    安装 + 配置 agent
    ./install.sh --agent AGENT      只配置指定 agent
    ./install.sh --list-agents      列出支持的 agent
    ./install.sh --update           更新 skill 仓库
    ./install.sh --uninstall        卸载
    ./install.sh --help             显示帮助

说明:
    本脚本只负责克隆仓库和创建软链接。
    依赖检查由 agent 自行完成，参考 ~/.p-skills/DEPENDENCIES.md

集成 Skills:
    安装后自动包含以下工具的 skills（MCP 需用户自行安装）：
    - AgentMemory: 持久记忆管理（recall, remember, recap 等）
    - CodeGraph: 代码图谱分析
    - Semble: 语义代码搜索
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
    echo "  P Skills — 安装"
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

            log_info "集成 Skills（已包含）："
            echo "  - AgentMemory: 持久记忆管理（recall, remember, recap 等）"
            echo "  - CodeGraph: 代码图谱分析"
            echo "  - Semble: 语义代码搜索"
            echo ""
            log_info "集成 MCP 安装（需用户自行完成）："
            echo "  - AgentMemory: https://github.com/rohitg00/agentmemory"
            echo "  - CodeGraph: https://github.com/colbymchenry/codegraph"
            echo "  - Semble: https://github.com/MinishLab/semble"
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
