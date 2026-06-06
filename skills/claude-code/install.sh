#!/usr/bin/env bash
set -euo pipefail

# P-Skills Claude Code Module Installer
# Installs hooks, creates required directories, merges configuration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P_SKILLS_DIR="${HOME}/.p-skills"
CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
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

  if [ ! -f "$SETTINGS_FILE" ]; then
    info "No settings.json found, nothing to do."
    return 0
  fi

  if ! grep -q "p-skills" "$SETTINGS_FILE" 2>/dev/null; then
    info "No P-Skills hooks found in settings.json."
    return 0
  fi

  if command -v node >/dev/null 2>&1; then
    node -e "
      const fs = require('fs');
      const file = '${SETTINGS_FILE}';
      let settings;
      try { settings = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { process.exit(0); }
      if (!settings || typeof settings !== 'object' || !settings.hooks) process.exit(0);

      let removed = 0;
      const hooks = settings.hooks;

      for (const event of Object.keys(hooks)) {
        if (!Array.isArray(hooks[event])) continue;

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
          if (group.hooks && group.hooks.length === 0) return false;
          return true;
        });

        if (hooks[event].length === 0) delete hooks[event];
      }

      if (removed > 0) {
        fs.writeFileSync(file, JSON.stringify(settings, null, 2) + '\n');
        console.log('Removed ' + removed + ' P-Skills hook(s) from settings.json.');
      } else {
        console.log('No P-Skills hooks to remove.');
      }
    "
  else
    warn "Node.js not found. Cannot automatically remove hooks."
    warn "Please manually remove P-Skills entries from: $SETTINGS_FILE"
  fi

  # Clean up legacy hooks.json if it exists
  if [ -f "${CLAUDE_DIR}/hooks.json" ]; then
    rm -f "${CLAUDE_DIR}/hooks.json"
    info "Removed legacy hooks.json"
  fi

  # Remove Codex hooks from config.toml
  local codex_config="${HOME}/.codex/config.toml"
  if [ -f "$codex_config" ] && command -v node >/dev/null 2>&1; then
    if grep -q "\[hooks\]" "$codex_config" 2>/dev/null; then
      node -e "
        const fs = require('fs');
        const file = '${codex_config}';
        let content = fs.readFileSync(file, 'utf8');
        // Remove [hooks] section
        const hooksIdx = content.indexOf('\n[hooks]');
        if (hooksIdx !== -1) {
          content = content.substring(0, hooksIdx);
        }
        // Remove legacy hooks path
        content = content.replace(/^hooks = \".*hooks\.json\".*\n?/gm, '');
        fs.writeFileSync(file, content.trimEnd() + '\n');
        console.log('Removed hooks from Codex config.toml');
      "
    fi
  fi
  # Clean up legacy hooks.json
  rm -f "${HOME}/.codex/hooks.json"

  # Remove Cursor hooks (remove p-skills entries, keep others)
  local cursor_hooks="${HOME}/.cursor/hooks.json"
  if [ -f "$cursor_hooks" ] && command -v node >/dev/null 2>&1; then
    if grep -q "p-skills" "$cursor_hooks" 2>/dev/null; then
      node -e "
        const fs = require('fs');
        const file = '${cursor_hooks}';
        let hooks;
        try { hooks = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { process.exit(0); }
        if (!hooks || !hooks.hooks) process.exit(0);

        let removed = 0;
        for (const event of Object.keys(hooks.hooks)) {
          if (!Array.isArray(hooks.hooks[event])) continue;
          const before = hooks.hooks[event].length;
          hooks.hooks[event] = hooks.hooks[event].filter(h =>
            !(h.command && h.command.includes('p-skills'))
          );
          removed += before - hooks.hooks[event].length;
          if (hooks.hooks[event].length === 0) delete hooks.hooks[event];
        }

        if (removed > 0) {
          fs.writeFileSync(file, JSON.stringify(hooks, null, 2) + '\n');
          console.log('Removed ' + removed + ' P-Skills hook(s) from Cursor hooks.json');
        } else {
          console.log('No P-Skills hooks to remove from Cursor.');
        }
      "
    fi
  fi

  # Remove OpenCode plugin
  local opencode_plugin="${HOME}/.config/opencode/plugins/p-skills-learning.ts"
  local opencode_config="${HOME}/.config/opencode/opencode.json"
  if [ -f "$opencode_plugin" ]; then
    rm -f "$opencode_plugin"
    info "Removed OpenCode plugin: $opencode_plugin"
    # Remove from plugin list in config
    if [ -f "$opencode_config" ] && command -v node >/dev/null 2>&1; then
      node -e "
        const fs = require('fs');
        const file = '${opencode_config}';
        let config;
        try { config = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { process.exit(0); }
        if (config.plugin && Array.isArray(config.plugin)) {
          config.plugin = config.plugin.filter(p => p !== 'p-skills-learning');
          fs.writeFileSync(file, JSON.stringify(config, null, 2) + '\n');
          console.log('Removed p-skills-learning from OpenCode plugins');
        }
      "
    fi
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
  "session-tracker.js"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [ ! -f "${SCRIPTS_DIR}/${script}" ]; then
    error "Missing hook script: ${SCRIPTS_DIR}/${script}"
    exit 1
  fi
done

info "All ${#REQUIRED_SCRIPTS[@]} hook scripts verified."

# ── Merge hooks into settings.json ────────────────────────────────────────────

mkdir -p "$CLAUDE_DIR"

# Merge p-skills hooks into settings.json, preserving existing hooks
node -e "
  const fs = require('fs');
  const settingsFile = '${SETTINGS_FILE}';
  const scriptsDir = '${SCRIPTS_DIR}';

  // Load existing settings or create empty
  let settings = {};
  try { settings = JSON.parse(fs.readFileSync(settingsFile, 'utf8')); } catch {}
  if (!settings.hooks) settings.hooks = {};

  // P-Skills hooks to register
  const pSkillsHooks = {
    PreToolUse: [
      {
        matcher: 'Edit|Write|MultiEdit',
        hooks: [
          { type: 'command', command: 'node ' + scriptsDir + '/gateguard.js' },
          { type: 'command', command: 'node ' + scriptsDir + '/config-protection.js' }
        ]
      },
      {
        matcher: 'Bash',
        hooks: [
          { type: 'command', command: 'node ' + scriptsDir + '/gateguard.js' }
        ]
      }
    ],
    PostToolUse: [
      {
        matcher: 'Edit|Write|MultiEdit',
        hooks: [
          { type: 'command', command: 'node ' + scriptsDir + '/quality-gate.js' },
          { type: 'command', command: 'node ' + scriptsDir + '/learning-observer.js' },
          { type: 'command', command: 'node ' + scriptsDir + '/meta-skill-update.js' },
          { type: 'command', command: 'node ' + scriptsDir + '/session-tracker.js' }
        ]
      },
      {
        matcher: 'Bash',
        hooks: [
          { type: 'command', command: 'node ' + scriptsDir + '/learning-observer.js' },
          { type: 'command', command: 'node ' + scriptsDir + '/session-tracker.js' }
        ]
      },
      {
        matcher: '*',
        hooks: [
          { type: 'command', command: 'node ' + scriptsDir + '/context-monitor.js' }
        ]
      }
    ],
    SessionStart: [
      {
        matcher: '*',
        hooks: [
          { type: 'command', command: 'node ' + scriptsDir + '/session-recovery.js' },
          { type: 'command', command: 'node ' + scriptsDir + '/session-learning.js' }
        ]
      }
    ],
    Stop: [
      {
        matcher: '*',
        hooks: [
          { type: 'command', command: 'node ' + scriptsDir + '/session-summary.js' },
          { type: 'command', command: 'node ' + scriptsDir + '/session-tracker.js' }
        ]
      }
    ]
  };

  // Merge: remove old p-skills hooks, then add new ones
  for (const event of Object.keys(pSkillsHooks)) {
    if (!settings.hooks[event]) {
      settings.hooks[event] = [];
    }

    // Remove existing p-skills entries
    settings.hooks[event] = settings.hooks[event]
      .map(group => {
        if (group.hooks && Array.isArray(group.hooks)) {
          group.hooks = group.hooks.filter(h =>
            !(h.command && h.command.includes('p-skills'))
          );
        }
        return group;
      })
      .filter(group => !(group.hooks && group.hooks.length === 0));

    // Add new p-skills entries
    settings.hooks[event].push(...pSkillsHooks[event]);
  }

  fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2) + '\n');
  console.log('Hooks merged into: ' + settingsFile);
"

info "Hooks merged into: $SETTINGS_FILE"

# Clean up legacy hooks.json if it exists
if [ -f "${CLAUDE_DIR}/hooks.json" ]; then
  rm -f "${CLAUDE_DIR}/hooks.json"
  info "Removed legacy hooks.json"
fi

# ── Install hooks for Codex ──────────────────────────────────────────────────

CODEX_DIR="${HOME}/.codex"
CODEX_CONFIG_FILE="${CODEX_DIR}/config.toml"

if [ -d "$CODEX_DIR" ] && [ -f "$CODEX_CONFIG_FILE" ]; then
  info "Detected Codex installation, installing hooks..."

  # Remove old [hooks] section if present, then append new one
  if command -v node >/dev/null 2>&1; then
    node -e "
      const fs = require('fs');
      const file = '${CODEX_CONFIG_FILE}';
      let content = fs.readFileSync(file, 'utf8');

      // Remove existing [hooks] section and everything after it
      const hooksIdx = content.indexOf('\n[hooks]');
      if (hooksIdx !== -1) {
        content = content.substring(0, hooksIdx);
      }

      // Remove legacy hooks.json path reference
      content = content.replace(/^hooks = \".*hooks\.json\".*\n?/gm, '');

      const scriptsDir = '${SCRIPTS_DIR}';
      const hooks = \`

[hooks]
PreToolUse = [
  {command = \"node \${scriptsDir}/gateguard.js\", matcher = \"Edit|Write|MultiEdit\"},
  {command = \"node \${scriptsDir}/config-protection.js\", matcher = \"Edit|Write|MultiEdit\"},
  {command = \"node \${scriptsDir}/gateguard.js\", matcher = \"Bash\"}
]
PostToolUse = [
  {command = \"node \${scriptsDir}/quality-gate.js\", matcher = \"Edit|Write|MultiEdit\"},
  {command = \"node \${scriptsDir}/learning-observer.js\", matcher = \"Edit|Write|MultiEdit|Bash\"},
  {command = \"node \${scriptsDir}/meta-skill-update.js\", matcher = \"Edit|Write|MultiEdit\"},
  {command = \"node \${scriptsDir}/session-tracker.js\", matcher = \"Edit|Write|MultiEdit|Bash\"},
  {command = \"node \${scriptsDir}/context-monitor.js\"}
]
SessionStart = [
  {command = \"node \${scriptsDir}/session-recovery.js\"},
  {command = \"node \${scriptsDir}/session-learning.js\"}
]
Stop = [
  {command = \"node \${scriptsDir}/session-summary.js\"},
  {command = \"node \${scriptsDir}/session-tracker.js\"}
]\`;

      fs.writeFileSync(file, content.trimEnd() + hooks + '\n');
      console.log('Hooks written to config.toml');
    "
  fi

  # Clean up legacy hooks.json
  if [ -f "${CODEX_DIR}/hooks.json" ]; then
    rm -f "${CODEX_DIR}/hooks.json"
    info "Removed legacy hooks.json"
  fi

  info "Codex hooks installed in config.toml"
else
  info "Codex not detected, skipping"
fi

# ── Install hooks for Cursor ─────────────────────────────────────────────────

CURSOR_DIR="${HOME}/.cursor"
CURSOR_HOOKS_FILE="${CURSOR_DIR}/hooks.json"

if [ -d "$CURSOR_DIR" ]; then
  info "Detected Cursor installation, installing hooks..."

  # Read existing hooks.json to preserve non-p-skills hooks
  if [ -f "$CURSOR_HOOKS_FILE" ] && command -v node >/dev/null 2>&1; then
    node -e "
      const fs = require('fs');
      const file = '${CURSOR_HOOKS_FILE}';
      const scriptsDir = '${SCRIPTS_DIR}';

      let existing = { version: 1, hooks: {} };
      try { existing = JSON.parse(fs.readFileSync(file, 'utf8')); } catch {}

      // Cursor hooks format: flat {command, matcher} objects (no nested hooks array)
      const pSkillsHooks = {
        preToolUse: [
          { command: 'node ' + scriptsDir + '/gateguard.js', matcher: 'Write|Edit|MultiEdit' },
          { command: 'node ' + scriptsDir + '/gateguard.js', matcher: 'Shell' }
        ],
        postToolUse: [
          { command: 'node ' + scriptsDir + '/learning-observer.js', matcher: 'Write|Edit|MultiEdit|Shell' },
          { command: 'node ' + scriptsDir + '/meta-skill-update.js', matcher: 'Write|Edit|MultiEdit' },
          { command: 'node ' + scriptsDir + '/session-tracker.js', matcher: 'Write|Edit|MultiEdit|Shell' }
        ],
        sessionStart: [
          { command: 'node ' + scriptsDir + '/session-learning.js' }
        ],
        stop: [
          { command: 'node ' + scriptsDir + '/session-summary.js' },
          { command: 'node ' + scriptsDir + '/session-tracker.js' }
        ]
      };

      for (const [event, newHooks] of Object.entries(pSkillsHooks)) {
        if (!existing.hooks[event]) existing.hooks[event] = [];

        // Remove old p-skills hooks
        existing.hooks[event] = existing.hooks[event].filter(h =>
          !(h.command && h.command.includes('p-skills'))
        );

        // Add new p-skills hooks
        existing.hooks[event].push(...newHooks);
      }

      fs.writeFileSync(file, JSON.stringify(existing, null, 2) + '\n');
      console.log('Hooks merged into: ' + file);
    "
  else
    # No existing hooks.json, create fresh
    cat > "$CURSOR_HOOKS_FILE" << CURSOR_HOOKS_EOF
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      { "command": "node ${SCRIPTS_DIR}/gateguard.js", "matcher": "Write|Edit|MultiEdit" },
      { "command": "node ${SCRIPTS_DIR}/gateguard.js", "matcher": "Shell" }
    ],
    "postToolUse": [
      { "command": "node ${SCRIPTS_DIR}/learning-observer.js", "matcher": "Write|Edit|MultiEdit|Shell" },
      { "command": "node ${SCRIPTS_DIR}/meta-skill-update.js", "matcher": "Write|Edit|MultiEdit" },
      { "command": "node ${SCRIPTS_DIR}/session-tracker.js", "matcher": "Write|Edit|MultiEdit|Shell" }
    ],
    "sessionStart": [
      { "command": "node ${SCRIPTS_DIR}/session-learning.js" }
    ],
    "stop": [
      { "command": "node ${SCRIPTS_DIR}/session-summary.js" },
      { "command": "node ${SCRIPTS_DIR}/session-tracker.js" }
    ]
  }
}
CURSOR_HOOKS_EOF
  fi

  info "Cursor hooks written to: $CURSOR_HOOKS_FILE"
else
  info "Cursor not detected, skipping"
fi

# ── Install plugin for OpenCode ──────────────────────────────────────────────

OPENCODE_DIR="${HOME}/.config/opencode"
OPENCODE_PLUGIN_FILE="${OPENCODE_DIR}/plugins/p-skills-learning.ts"
OPENCODE_CONFIG_FILE="${OPENCODE_DIR}/opencode.json"

if [ -d "$OPENCODE_DIR" ]; then
  info "Detected OpenCode installation, installing learning plugin..."

  # Copy plugin file
  mkdir -p "${OPENCODE_DIR}/plugins"
  cat > "$OPENCODE_PLUGIN_FILE" << 'OPENCODE_PLUGIN_EOF'
import type { Plugin } from "@opencode-ai/plugin"
import { appendFileSync, mkdirSync, readFileSync, writeFileSync } from "fs"
import { join, dirname, extname, basename } from "path"
import { homedir } from "os"
import { execSync } from "child_process"
import { createHash } from "crypto"

const LEARNING_DIR = join(homedir(), ".p-skills", "learning")

function getProjectId(cwd: string): string {
  try {
    const remoteUrl = execSync("git remote get-url origin", {
      cwd, encoding: "utf8", timeout: 5000, stdio: ["pipe", "pipe", "pipe"],
    }).trim()
    return createHash("md5").update(remoteUrl.replace(/\.git$/, "")).digest("hex").substring(0, 12)
  } catch {
    return createHash("md5").update(basename(cwd)).digest("hex").substring(0, 12)
  }
}

function ensureDir(dir: string) { try { mkdirSync(dir, { recursive: true }) } catch {} }

function appendJsonl(filePath: string, data: Record<string, unknown>) {
  try { ensureDir(dirname(filePath)); appendFileSync(filePath, JSON.stringify(data) + "\n", "utf8") } catch {}
}

function updateSessionStats(sessionFile: string, toolName: string, observation: Record<string, unknown>) {
  ensureDir(dirname(sessionFile))
  let stats: Record<string, unknown>
  try { stats = JSON.parse(readFileSync(sessionFile, "utf8")) } catch {
    stats = { session_id: observation.session_id, started_at: observation.timestamp, tool_calls: {}, skill_triggers: [], total_calls: 0 }
  }
  const toolCalls = stats.tool_calls as Record<string, number>
  toolCalls[toolName] = (toolCalls[toolName] || 0) + 1
  stats.total_calls = (stats.total_calls as number) + 1
  stats.last_updated = observation.timestamp
  try { writeFileSync(sessionFile, JSON.stringify(stats, null, 2), "utf8") } catch {}
}

const OBSERVED_TOOLS = new Set(["edit", "write", "multiedit", "bash", "shell"])

export const PSkillsLearningPlugin: Plugin = async () => {
  const sessionId = `opencode-${Date.now()}`
  return {
    "tool.execute.after": async (input, output) => {
      const toolName = String(input?.tool ?? "").toLowerCase()
      if (!OBSERVED_TOOLS.has(toolName)) return
      const args = (output?.args ?? {}) as Record<string, unknown>
      const cwd = String(args.cwd || process.cwd())
      const projectId = getProjectId(cwd)
      const filePath = String(args.file_path || args.path || "")
      const fileExt = filePath ? extname(filePath) : ""
      const observation: Record<string, unknown> = {
        timestamp: new Date().toISOString(), session_id: sessionId, tool: toolName,
        file_path: filePath, file_ext: fileExt, project_id: projectId,
        skill_triggered: null, user_reverted: false, user_manually_edited: false,
        tool_input_size: JSON.stringify(args).length, agent: "opencode",
      }
      appendJsonl(join(LEARNING_DIR, "projects", projectId, "observations.jsonl"), observation)
      updateSessionStats(join(LEARNING_DIR, "projects", projectId, "sessions", `${sessionId}.json`), toolName, observation)
    },
  }
}
OPENCODE_PLUGIN_EOF

  info "OpenCode plugin written to: $OPENCODE_PLUGIN_FILE"

  # Register plugin in opencode.json if not already present
  if [ -f "$OPENCODE_CONFIG_FILE" ] && command -v node >/dev/null 2>&1; then
    node -e "
      const fs = require('fs');
      const file = '${OPENCODE_CONFIG_FILE}';
      let config;
      try { config = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { process.exit(0); }
      if (!config.plugin) config.plugin = [];
      if (!config.plugin.includes('p-skills-learning')) {
        config.plugin.push('p-skills-learning');
        fs.writeFileSync(file, JSON.stringify(config, null, 2) + '\n');
        console.log('Registered p-skills-learning plugin');
      } else {
        console.log('Plugin already registered');
      }
    "
  fi

  info "OpenCode learning plugin installed"
else
  info "OpenCode not detected, skipping"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
info "Installation complete!"
echo ""
echo "  Hooks (${#REQUIRED_SCRIPTS[@]} scripts):"
echo "    PreToolUse:   gateguard, config-protection"
echo "    PostToolUse:  quality-gate, learning-observer, meta-skill-update, context-monitor"
echo "    SessionStart: session-recovery, session-learning"
echo "    Stop:         session-summary"
echo ""
echo "  Agents:"
echo "    Claude Code: hooks merged into ~/.claude/settings.json"
if [ -d "$CODEX_DIR" ]; then
  echo "    Codex:       hooks written to ~/.codex/hooks.json"
fi
if [ -d "$CURSOR_DIR" ]; then
  echo "    Cursor:      hooks merged into ~/.cursor/hooks.json"
fi
if [ -d "$OPENCODE_DIR" ]; then
  echo "    OpenCode:    plugin installed to ~/.config/opencode/plugins/"
fi
echo ""
echo "  Directories:"
echo "    - ${GATEGUARD_DIR}"
echo "    - ${SESSIONS_DIR}"
echo "    - ${LEARNING_DIR}"
echo ""
echo "  To uninstall: $0 --uninstall"
echo ""
