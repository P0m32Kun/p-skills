#!/usr/bin/env bash
set -euo pipefail

# Links all skills in the repository to ~/.pi/agent/skills, so that
# they can be discovered by pi.
#
# Usage:
#   ./scripts/link-skills.sh          # Link all skills
#   ./scripts/link-skills.sh --dry-run # Preview without linking

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.pi/agent/skills"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "=== DRY RUN (no changes) ==="
fi

# Safety check: if DEST is a symlink into this repo, bail out
if [ -L "$DEST" ]; then
  resolved="$(readlink -f "$DEST")"
  case "$resolved" in
    "$REPO"|"$REPO"/*)
      echo "error: $DEST is a symlink into this repo ($resolved)." >&2
      echo "Remove it (rm \"$DEST\") and re-run; the script will recreate it as a real dir." >&2
      exit 1
      ;;
  esac
fi

mkdir -p "$DEST"

count=0
find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -print0 |
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  name="$(basename "$src")"
  target="$DEST/$name"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    if $DRY_RUN; then
      echo "[skip] $name (exists, not a symlink)"
    else
      rm -rf "$target"
    fi
  fi

  if $DRY_RUN; then
    echo "[link] $name -> $src"
  else
    ln -sfn "$src" "$target"
    echo "linked $name -> $src"
  fi
  count=$((count + 1))
done

echo ""
echo "Done. $count skills linked to $DEST"
