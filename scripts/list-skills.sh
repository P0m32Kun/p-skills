#!/usr/bin/env bash
set -euo pipefail

# Lists all skills in the repository
REPO="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO"
find skills -name SKILL.md -not -path '*/node_modules/*' | sed 's|^\./||' | sort
