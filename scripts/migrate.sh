#!/usr/bin/env bash
set -euo pipefail

# Migration script: transition from old p-skills symlink to new per-skill symlinks
#
# Old structure: ~/.pi/agent/skills/p-skills -> ~/.p-skills
# New structure: ~/.pi/agent/skills/<skill-name> -> ~/.p-skills/skills/<skill-name>

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.pi/agent/skills"
OLD_SYMLINK="$DEST/p-skills"

echo "=== P-Skills Migration ==="
echo ""
echo "This will:"
echo "  1. Remove old symlink: $OLD_SYMLINK"
echo "  2. Create per-skill symlinks in $DEST"
echo ""

# Check if old symlink exists
if [ -L "$OLD_SYMLINK" ]; then
  echo "[info] Found old symlink: $OLD_SYMLINK -> $(readlink "$OLD_SYMLINK")"
  echo ""
  read -p "Remove old symlink and create new per-skill symlinks? (y/N) " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm "$OLD_SYMLINK"
    echo "[done] Removed old symlink"
  else
    echo "[skip] Migration cancelled"
    exit 0
  fi
else
  echo "[info] No old symlink found, proceeding with fresh install"
fi

echo ""
echo "=== Creating per-skill symlinks ==="
echo ""

# Run link-skills.sh
"$REPO/scripts/link-skills.sh"

echo ""
echo "=== Migration complete ==="
echo ""
echo "Next steps:"
echo "  1. Restart your pi session"
echo "  2. Skills should now be auto-discovered"
echo "  3. Test with: '帮我修复这个 bug' (should trigger fix-bug skill)"
