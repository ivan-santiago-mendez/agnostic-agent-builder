#!/usr/bin/env bash
# Initializes the memory bank SQLite database.
# Safe to run multiple times — uses CREATE TABLE IF NOT EXISTS.
#
# Usage:
#   bash scripts/mb-migrate.sh               # uses default path
#   MEMORY_BANK_DB=/custom/path.db bash scripts/mb-migrate.sh

set -euo pipefail

# When running from Git Bash on Windows (OSTYPE=msys), delegate to WSL so we
# use the Linux sqlite3 and write to the WSL home, which is the same path the
# session hooks resolve at runtime.
if [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]]; then
  exec wsl -e bash -c "cd /home/$(wsl -e whoami) && bash /home/$(wsl -e whoami)/0_repo_wsl/taulia-hackaton-2026/scripts/mb-migrate.sh"
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB_PATH="${MEMORY_BANK_DB:-$PROJECT_ROOT/.claude/memory-banks/agents-memory-manager}"
DB_DIR="$(dirname "$DB_PATH")"

if ! command -v sqlite3 &>/dev/null; then
  echo "ERROR: sqlite3 is not installed. Install it and retry."
  exit 1
fi

mkdir -p "$DB_DIR"

sqlite3 "$DB_PATH" <<'SQL'
CREATE TABLE IF NOT EXISTS documents (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL UNIQUE,
  category   TEXT NOT NULL CHECK(category IN (
               'workflow','template','architecture','standard',
               'scripts','agent','process','runbook','api'
             )),
  content    TEXT NOT NULL,
  tags       TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS tickets (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  key          TEXT NOT NULL UNIQUE,
  summary      TEXT,
  status       TEXT,
  context_path TEXT,
  archived     INTEGER NOT NULL DEFAULT 0,
  created_at   TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS cache (
  key        TEXT PRIMARY KEY,
  value      TEXT,
  expires_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_documents_category   ON documents(category);
CREATE INDEX IF NOT EXISTS idx_documents_updated_at ON documents(updated_at);
CREATE INDEX IF NOT EXISTS idx_tickets_archived     ON tickets(archived);
CREATE INDEX IF NOT EXISTS idx_tickets_updated_at   ON tickets(updated_at);
SQL

echo "Memory bank initialized at: $DB_PATH"
sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" \
  | awk '{print "  table: " $0}'
