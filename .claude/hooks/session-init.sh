#!/usr/bin/env bash
# SessionStart hook — resets the first-turn sentinel so the UserPromptSubmit
# guard fires on the first message of every new session.

set -euo pipefail

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
SENTINEL_DIR="$PROJECT_ROOT/.context"

mkdir -p "$SENTINEL_DIR"
rm -f "$SENTINEL_DIR/.session-init-active"
