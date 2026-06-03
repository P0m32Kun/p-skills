#!/usr/bin/env bash
set -euo pipefail

# Cleanup script: remove old symlinks and migrate to new per-skill structure
#
# Usage:
#   ./scripts/cleanup-old-symlinks.sh              # Interactive mode
#   ./scripts/cleanup-old-symlinks.sh --dry-run     # Preview without changes
#   ./scripts/cleanup-old-symlinks.sh --auto         # Non-interactive, remove all old symlinks

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=false
AUTO=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --auto) AUTO=true ;;
  esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  P-Skills Cleanup & Migration"
echo "=========================================="
echo ""

if $DRY_RUN; then
  echo -e "${YELLOW}[DRY RUN] No changes will be made${NC}"
  echo ""
fi

# Define old symlinks to remove
# Format: "directory:symlink_name"
OLD_SYMLINKS=(
  "$HOME/.pi/agent/skills/p-skills"
  "$HOME/.claude/skills/p-skills"
  "$HOME/.claude/skills/security-dev-skills"
  "$HOME/.cursor/skills/p-skills"
  "$HOME/.cursor/skills/security-dev-skills"
  "$HOME/.codex/skills/p-skills"
)

# Also check for any symlink pointing to .p-skills or .security-dev-skills
EXTRA_DIRS=(
  "$HOME/.pi/agent/skills"
  "$HOME/.claude/skills"
  "$HOME/.cursor/skills"
  "$HOME/.codex/skills"
)

found_count=0
removed_count=0

echo "Step 1: Finding old symlinks..."
echo ""

# Check known old symlinks
for link in "${OLD_SYMLINKS[@]}"; do
  if [ -L "$link" ]; then
    target="$(readlink "$link")"
    echo -e "  ${RED}[found]${NC} $link -> $target"
    found_count=$((found_count + 1))
    
    if ! $DRY_RUN; then
      if $AUTO || [ -t 0 ]; then
        rm "$link"
        echo -e "  ${GREEN}[removed]${NC} $link"
        removed_count=$((removed_count + 1))
      fi
    fi
  fi
done

# Scan for any other symlinks pointing to our repos
for dir in "${EXTRA_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    while IFS= read -r -d '' link; do
      target="$(readlink -f "$link" 2>/dev/null || true)"
      if [[ "$target" == *".p-skills"* ]] || [[ "$target" == *".security-dev-skills"* ]]; then
        link_name="$(basename "$link")"
        # Skip if already processed
        if [[ " ${OLD_SYMLINKS[@]} " =~ " ${link} " ]]; then
          continue
        fi
        echo -e "  ${RED}[found]${NC} $link -> $(readlink "$link")"
        found_count=$((found_count + 1))
        
        if ! $DRY_RUN; then
          if $AUTO || [ -t 0 ]; then
            rm "$link"
            echo -e "  ${GREEN}[removed]${NC} $link"
            removed_count=$((removed_count + 1))
          fi
        fi
      fi
    done < <(find "$dir" -maxdepth 1 -type l -print0 2>/dev/null)
  fi
done

echo ""
echo "Found: $found_count old symlinks"
if ! $DRY_RUN; then
  echo "Removed: $removed_count"
fi

# Step 2: Run link-skills.sh for pi
echo ""
echo "Step 2: Creating new per-skill symlinks for pi..."
echo ""

if $DRY_RUN; then
  "$REPO/scripts/link-skills.sh" --dry-run
else
  "$REPO/scripts/link-skills.sh"
fi

# Step 3: Summary
echo ""
echo "=========================================="
echo "  Summary"
echo "=========================================="
echo ""

if $DRY_RUN; then
  echo -e "${YELLOW}This was a dry run. To apply changes:${NC}"
  echo ""
  echo "  ./scripts/cleanup-old-symlinks.sh"
  echo ""
else
  echo -e "${GREEN}Cleanup complete!${NC}"
  echo ""
  echo "Old symlinks removed: $removed_count"
  echo ""
  echo "New symlinks created in: ~/.pi/agent/skills/"
  echo ""
  echo "Next steps:"
  echo "  1. Restart your pi session"
  echo "  2. Skills should now be auto-discovered"
  echo "  3. Test: '帮我修复这个 bug' (should trigger fix-bug)"
  echo ""
  echo "For Claude Code, run separately:"
  echo "  cd ~/.p-skills && ./scripts/link-skills.sh"
  echo "  (or use the Claude plugin system)"
fi
