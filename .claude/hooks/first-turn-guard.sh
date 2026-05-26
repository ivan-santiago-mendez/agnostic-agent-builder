#!/usr/bin/env bash
# UserPromptSubmit hook — fires on every user message.
# On the FIRST message of a session (sentinel absent), injects a mandatory
# initialization instruction into Claude's context via additionalContext.
# On subsequent messages, exits silently (sentinel present).

set -euo pipefail

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
SENTINEL_DIR="$PROJECT_ROOT/.context"
SENTINEL="$SENTINEL_DIR/.session-init-$(date +%Y%m%d-%H%M%S)-$$"
ACTIVE_SENTINEL=$(ls "$SENTINEL_DIR"/.session-init-* 2>/dev/null | head -1 || true)

# If sentinel exists → not the first turn, exit silently
if [ -n "$ACTIVE_SENTINEL" ]; then
  exit 0
fi

# First turn — create sentinel so this only fires once
mkdir -p "$SENTINEL_DIR"
touch "$SENTINEL_DIR/.session-init-active"

# Output JSON with additionalContext to prepend to Claude's prompt
cat <<'EOF'
{
  "additionalContext": "🚨 MANDATORY SESSION INITIALIZATION — DO THIS BEFORE ANYTHING ELSE\n\nBefore responding to the user's message, you MUST run BOTH of the following concurrently:\n  1. Invoke the `agents-infrastructure-manager` agent — full environment health check\n  2. Invoke the `agents-memory-manager` agent — load active tickets and relevant context\n\nOnly after both complete should you respond to the user's actual request."
}
EOF
