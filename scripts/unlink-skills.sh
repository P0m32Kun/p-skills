#!/usr/bin/env bash
set -euo pipefail

# Uninstall script: remove all p-skills symlinks from ~/.pi/agent/skills/
#
# Usage:
#   ./scripts/unlink-skills.sh          # Remove all symlinks
#   ./scripts/unlink-skills.sh --dry-run # Preview without removing
#   ./scripts/unlink-skills.sh --all     # Remove symlinks AND the repo directory

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.pi/agent/skills"
DRY_RUN=false
REMOVE_ALL=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      echo "=== DRY RUN (no changes) ==="
      ;;
    --all)
      REMOVE_ALL=true
      ;;
  esac
done

echo "=== P-Skills Uninstall ==="
echo ""

# Check if destination exists
if [ ! -d "$DEST" ]; then
  echo "[info] $DEST does not exist, nothing to clean"
  exit 0
fi

# Find all symlinks pointing to this repo
count=0
links_to_remove=()

while IFS= read -r -d '' link; do
  target="$(readlink -f "$link" 2>/dev/null || true)"
  if [[ "$target" == "$REPO/skills/"* ]]; then
    links_to_remove+=("$link")
    count=$((count + 1))
  fi
done < <(find "$DEST" -maxdepth 1 -type l -print0 2>/dev/null)

if [ $count -eq 0 ]; then
  echo "[info] No p-skills symlinks found in $DEST"
else
  echo "Found $count symlinks to remove:"
  echo ""
  for link in "${links_to_remove[@]}"; do
    name="$(basename "$link")"
    target="$(readlink "$link")"
    if $DRY_RUN; then
      echo "  [remove] $name -> $target"
    else
      rm "$link"
      echo "  [removed] $name"
    fi
  done
fi

# Optionally remove old p-skills symlink
OLD_SYMLINK="$DEST/p-skills"
if [ -L "$OLD_SYMLINK" ]; then
  echo ""
  if $DRY_RUN; then
    echo "  [remove] p-skills (old symlink) -> $(readlink "$OLD_SYMLINK")"
  else
    rm "$OLD_SYMLINK"
    echo "  [removed] p-skills (old symlink)"
  fi
fi

# Optionally remove the repo itself
if $REMOVE_ALL; then
  echo ""
  if $DRY_RUN; then
    echo "  [remove] $REPO (entire repo)"
  else
    echo ""
    read -p "Remove the entire p-skills repo at $REPO? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -rf "$REPO"
      echo "  [removed] $REPO"
    else
      echo "  [skip] Repo preserved"
    fi
  fi
fi

echo ""
if $DRY_RUN; then
  echo "=== DRY RUN complete. Run without --dry-run to apply changes ==="
else
  echo "=== Uninstall complete ==="
  if [ $count -gt 0 ]; then
    echo ""
    echo "Removed $count skill symlinks"
    echo "Restart your pi session for changes to take effect"
  fi
fi
