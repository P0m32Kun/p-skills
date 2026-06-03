#!/usr/bin/env bash
set -euo pipefail

# P-Skills Claude Code Module Installer
# Installs hooks, creates required directories, merges configuration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P_SKILLS_DIR="${HOME}/.p-skills"
CLAUDE_DIR="${HOME}/.claude"
HOOKS_FILE="${CLAUDE_DIR}/hooks.json"
GATEGUARD_DIR="${P_SKILLS_DIR}/gateguard"
SESSIONS_DIR="${P_SKILLS_DIR}/sessions"
LEARNING_DIR="${P_SKILLS_DIR}/learning"
SCRIPTS_DIR="${SCRIPT_DIR}/hooks/scripts"

# Colors (only when stdout is a terminal)
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  GREEN='' YELLOW='' RED='' NC=''
fi

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Uninstall ──────────────────────────────────────────────────────────────────

uninstall() {
  info "Uninstalling P-Skills Claude Code hooks..."

  if [ ! -f "$HOOKS_FILE" ]; then
    info "No hooks.json found, nothing to do."
    return 0
  fi

  if ! grep -q "p-skills" "$HOOKS_FILE" 2>/dev/null; then
    info "No P-Skills hooks found in hooks.json."
    return 0
  fi

  if command -v node >/dev/null 2>&1; then
    node -e "
      const fs = require('fs');
      const file = '${HOOKS_FILE}';
      let hooks;
      try { hooks = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { process.exit(0); }
      if (!hooks || typeof hooks !== 'object') process.exit(0);

      let removed = 0;

      for (const event of Object.keys(hooks)) {
        if (!Array.isArray(hooks[event])) continue;

        // Handle Claude Code format: array of {matcher, hooks: [{type, command}]}
        hooks[event] = hooks[event].map(group => {
          if (group.hooks && Array.isArray(group.hooks)) {
            const before = group.hooks.length;
            group.hooks = group.hooks.filter(h =>
              !(h.command && h.command.includes('p-skills'))
            );
            removed += before - group.hooks.length;
          }
          return group;
        }).filter(group => {
          // Remove empty groups
          if (group.hooks && group.hooks.length === 0) return false;
          return true;
        });

        // Handle legacy format: array of {type, command}
        if (hooks[event].length > 0 && hooks[event][0].type) {
          const before = hooks[event].length;
          hooks[event] = hooks[event].filter(h =>
            !(h.command && h.command.includes('p-skills'))
          );
          removed += before - hooks[event].length;
        }

        if (hooks[event].length === 0) delete hooks[event];
      }

      if (removed > 0) {
        fs.writeFileSync(file, JSON.stringify(hooks, null, 2) + '\n');
        console.log('Removed ' + removed + ' P-Skills hook(s).');
      } else {
        console.log('No P-Skills hooks to remove.');
      }
    "
  else
    warn "Node.js not found. Cannot automatically remove hooks."
    warn "Please manually remove P-Skills entries from: $HOOKS_FILE"
  fi

  info "Uninstall complete."
  info "Directories ${GATEGUARD_DIR}, ${SESSIONS_DIR}, ${LEARNING_DIR} were not removed (may contain user data)."
}

# ── Argument parsing ───────────────────────────────────────────────────────────

if [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "-u" ]; then
  uninstall
  exit 0
fi

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [--uninstall|--help]"
  echo ""
  echo "Installs P-Skills Claude Code hooks and creates required directories."
  echo ""
  echo "Options:"
  echo "  --uninstall, -u   Remove P-Skills hooks from hooks.json"
  echo "  --help, -h        Show this help"
  exit 0
fi

# ── Pre-flight checks ─────────────────────────────────────────────────────────

if ! command -v node >/dev/null 2>&1; then
  error "Node.js is required but not found in PATH."
  error "Install Node.js: https://nodejs.org/"
  exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 14 ] 2>/dev/null; then
  error "Node.js >= 14 required, found: $(node -v)"
  exit 1
fi

info "Node.js $(node -v) detected."

# ── Create directories ────────────────────────────────────────────────────────

for dir in "$GATEGUARD_DIR" "$SESSIONS_DIR" "$LEARNING_DIR"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    info "Created: $dir"
  fi
done

# ── Verify hook scripts exist ─────────────────────────────────────────────────

REQUIRED_SCRIPTS=(
  "gateguard.js"
  "config-protection.js"
  "quality-gate.js"
  "context-monitor.js"
  "learning-observer.js"
  "learning-evolve.js"
  "meta-skill-update.js"
  "session-recovery.js"
  "session-learning.js"
  "session-summary.js"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [ ! -f "${SCRIPTS_DIR}/${script}" ]; then
    error "Missing hook script: ${SCRIPTS_DIR}/${script}"
    exit 1
  fi
done

info "All ${#REQUIRED_SCRIPTS[@]} hook scripts verified."

# ── Merge hooks into hooks.json ───────────────────────────────────────────────

mkdir -p "$CLAUDE_DIR"

# Write the complete hooks.json directly (Claude Code format with matchers)
cat > "$HOOKS_FILE" << HOOKS_EOF
{
  "PreToolUse": [
    {
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [
        { "type": "command", "command": "node ${SCRIPTS_DIR}/gateguard.js" },
        { "type": "command", "command": "node ${SCRIPTS_DIR}/config-protection.js" }
      ]
    },
    {
      "matcher": "Bash",
      "hooks": [
        { "type": "command", "command": "node ${SCRIPTS_DIR}/gateguard.js" }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [
        { "type": "command", "command": "node ${SCRIPTS_DIR}/quality-gate.js" },
        { "type": "command", "command": "node ${SCRIPTS_DIR}/learning-observer.js" },
        { "type": "command", "command": "node ${SCRIPTS_DIR}/meta-skill-update.js" }
      ]
    },
    {
      "matcher": "Bash",
      "hooks": [
        { "type": "command", "command": "node ${SCRIPTS_DIR}/learning-observer.js" }
      ]
    },
    {
      "matcher": "*",
      "hooks": [
        { "type": "command", "command": "node ${SCRIPTS_DIR}/context-monitor.js" }
      ]
    }
  ],
  "SessionStart": [
    {
      "matcher": "*",
      "hooks": [
        { "type": "command", "command": "node ${SCRIPTS_DIR}/session-recovery.js" },
        { "type": "command", "command": "node ${SCRIPTS_DIR}/session-learning.js" }
      ]
    }
  ],
  "Stop": [
    {
      "matcher": "*",
      "hooks": [
        { "type": "command", "command": "node ${SCRIPTS_DIR}/session-summary.js" }
      ]
    }
  ]
}
HOOKS_EOF

info "Hooks written to: $HOOKS_FILE"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
info "Installation complete!"
echo ""
echo "  Hooks (${#REQUIRED_SCRIPTS[@]} scripts, 11 hook registrations):"
echo "    PreToolUse:   gateguard, config-protection"
echo "    PostToolUse:  quality-gate, learning-observer, meta-skill-update, context-monitor"
echo "    SessionStart: session-recovery, session-learning"
echo "    Stop:         session-summary"
echo ""
echo "  Directories:"
echo "    - ${GATEGUARD_DIR}"
echo "    - ${SESSIONS_DIR}"
echo "    - ${LEARNING_DIR}"
echo ""
echo "  To uninstall: $0 --uninstall"
echo ""
