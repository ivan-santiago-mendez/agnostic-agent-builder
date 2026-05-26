#!/usr/bin/env bash
# Runs at session start via SessionStart hook.
# Loads active tickets and relevant cache from the memory bank DB
# and prints them as context for the Claude session.

set -euo pipefail

# Git Bash on Windows: resolve to the WSL home so the path and sqlite3 binary match.
if [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]]; then
  WSL_USER="$(wsl -e sh -c 'echo $USER' 2>/dev/null || echo "")"
  DB_PATH="${MEMORY_BANK_DB:-//wsl.localhost/Ubuntu/home/${WSL_USER}/.claude/memory-banks/agents-memory-manager}"
  SQLITE3="wsl -e sqlite3"
else
  PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
  DB_PATH="${MEMORY_BANK_DB:-$PROJECT_ROOT/.claude/memory-banks/agents-memory-manager}"
  SQLITE3="sqlite3"
fi

if [ ! -f "$DB_PATH" ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║  ⚠️  MEMORY BANK NOT INITIALIZED                                 ║"
  echo "╠══════════════════════════════════════════════════════════════════╣"
  echo "║  DB not found at:                                                ║"
  echo "║    $DB_PATH"
  echo "║                                                                  ║"
  echo "║  Agents cannot persist or retrieve context until this is fixed.  ║"
  echo "║                                                                  ║"
  echo "║  ACTION REQUIRED — run ONE of the following:                     ║"
  echo "║    bash scripts/mb-migrate.sh          (from project root)       ║"
  echo "║    → or ask the Infrastructure Manager to set it up for you      ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo ""
  exit 0
fi

echo "=== Memory Bank: Active Tickets ==="
$SQLITE3 "$DB_PATH" \
  "SELECT key, summary, status FROM tickets WHERE archived = 0 ORDER BY updated_at DESC LIMIT 10;" \
  2>/dev/null || echo "(no active tickets)"

echo ""
echo "=== Memory Bank: Cache ==="
$SQLITE3 "$DB_PATH" \
  "SELECT key, value FROM cache WHERE (expires_at IS NULL OR expires_at > datetime('now')) LIMIT 20;" \
  2>/dev/null || echo "(cache empty)"
