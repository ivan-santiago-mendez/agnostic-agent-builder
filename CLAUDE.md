# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ⚡ FIRST TURN INITIALIZATION — MANDATORY, NO EXCEPTIONS

On the **very first user message of every session**, before generating ANY response, you MUST:

1. **Invoke `agents-infrastructure-manager`** — run a full environment health check.
2. **Invoke `agents-memory-manager`** — load active tickets and relevant context.

Run both **concurrently**. Do not skip, defer, or summarize them away. Do not respond to the user's message until both have completed.

This applies regardless of how trivial the user's first message appears.

---

## Agentic Mode

This project uses a multi-agent workflow system. All complex development tasks are orchestrated through specialized agents defined in `.claude/agents/`.

### Pre-flight Rule (mandatory)

Before ANY ticket operation, code change, or external system interaction:

1. Invoke `agents-memory-manager` to check for relevant context (active tickets, prior decisions, templates).
2. Check `.context/<TICKET-KEY>/` for an existing implementation plan before starting work.

### Memory Bank Access Rule

ALL reads and writes to the memory bank (knowledge store) **must be delegated to `agents-memory-manager`**. Never query the underlying DB directly from other agents or inline tool calls.

### Auto-Delegation Triggers

| Condition | Agent to invoke |
|---|---|
| New feature or significant change requested and requirements are defined | `architecture-advisor` |
| New code file created | `code-reviewer` then `test-generator` |
| File touches auth, permissions, or secrets | `security-auditor` |
| Ticket needs creating, updating, or transitioning | `ticket-administrator` |
| Any git write operation (commit, branch, push, worktree, tag, stash) | `version-control-administrator` — **delegate IMMEDIATELY, no pre-screening** |
| Complex multi-step task | `master-coordinator` |
| Documentation needs updating | `documentation-writer` |
| Shell command, process, tool install, or OS-level operation needed | `local-system-administrator` |

### Orchestration Progress Format

When running multi-step workflows, show live progress:

```
[1/5] ✅ Code Review        (4s)
[2/5] ⏳ Security Audit     (running...)
[3/5] ⬜ Test Generation
[4/5] ⬜ Documentation
[5/5] ⬜ Ticket Update
```

---

## Agents

| Agent | File | Responsibility |
|---|---|---|
| Master Coordinator | `agents/master-coordinator.md` | Orchestrates multi-step workflows |
| Infrastructure Manager | `agents/agents-infrastructure-manager.md` | **Stage 0 of every workflow** — verifies tools, hooks, memory banks, env vars, and tech stack health. Auto-fixes what it can. |
| Architecture Advisor | `agents/architecture-advisor.md` | **Stage 2 of every implementation** — reviews requirements, designs the technical solution, produces architecture-plan.md + ADR, issues gate verdict (APPROVED / NEEDS_REVISION / BLOCKED). |
| Version Control Administrator | `agents/version-control-administrator.md` | **Central VCS gateway** — owns ALL git write operations: staging, committing, branching, worktree lifecycle, push, PR prep, repository hygiene. No other agent runs git write commands directly. |
| Local System Administrator | `agents/local-system-administrator.md` | Cross-platform OS interface — detects platform, executes shell commands (bash/zsh/PowerShell/cmd), manages processes, and installs tools safely |
| Ticket Administrator | `agents/ticket-administrator.md` | Full ticket lifecycle — create, update, transition, comment, search, link (Jira, GitHub Issues, Linear) |
| Code Implementer | `agents/code-implementer.md` | Fetches tickets and implements changes — requires an APPROVED architecture plan |
| Code Reviewer | `agents/code-reviewer.md` | Reviews code quality and patterns |
| Security Auditor | `agents/security-auditor.md` | Scans for security vulnerabilities |
| Test Generator | `agents/test-generator.md` | Generates test specs |
| Documentation Writer | `agents/documentation-writer.md` | Creates and maintains documentation |
| Memory Manager | `agents/agents-memory-manager.md` | Single entry point for knowledge store |

---

## Memory Bank

The memory bank is a structured knowledge store (SQLite or compatible) at a path defined in project settings. It holds:

- **workflows** — step-by-step procedures
- **templates** — reusable document/code templates
- **architecture** — architectural decision records (ADRs)
- **standards** — coding conventions and quality rules
- **scripts** — utility script documentation
- **agents** — agent capability documentation
- **processes** — cross-cutting operational processes

Schema (three tables):

```sql
documents (id, name, category, content, tags, created_at, updated_at)
tickets   (id, key, summary, status, context_path, archived, created_at, updated_at)
cache     (key, value, expires_at)
```

---

## Context Folders

Each ticket gets a local context folder at `.context/<TICKET-KEY>/`:

```
.context/PROJ-123/
  implementation-plan.md   ← created before coding starts
  orchestration-state.json ← workflow resume state
  notes.md                 ← freeform notes
```

---

## Worktrees

**Working directly on `main` or `master` is PROHIBITED for any change in any repository — no exceptions.**

Every change — whether part of a ticket workflow or a standalone fix — must happen inside a dedicated worktree on its own branch. This applies to the hub repo, wiki repo, component repos, and any other repository under management.

### Convention
| Item | Pattern |
|---|---|
| **Directory** | `../agnostic-agent-builder-worktrees/<TICKET-KEY>/` |
| **Branch** | `feat/<TICKET-KEY>` · `fix/<TICKET-KEY>` · `chore/<TICKET-KEY>` · `hotfix/<TICKET-KEY>` |

### Lifecycle
1. **Created** — `version-control-administrator` runs `git worktree add` BEFORE any staging or committing, for every change in every repo
2. **Used** — `code-implementer`, `test-generator`, review agents, and any agent making file changes operate inside the worktree path
3. **Kept** — worktree persists until the PR is confirmed merged (never auto-deleted)
4. **Cleaned up** — `version-control-administrator` runs `git worktree remove` after merge confirmation

### Pre-Commit Gate
`version-control-administrator` MUST run a worktree check at Step 0 of every Stage & Commit operation:
- If current branch is `main`/`master` → **STOP**, create a worktree first, then proceed
- If already on a feature/fix/chore/hotfix branch → proceed normally

### Reference Commands
```bash
# Create worktree for a ticket
git worktree add ../agnostic-agent-builder-worktrees/PROJ-123 -b feat/PROJ-123

# List all active worktrees
git worktree list

# Remove after PR merge
git worktree remove ../agnostic-agent-builder-worktrees/PROJ-123
git branch -d feat/PROJ-123
```

---

## General Rules

- **No auto-commits** — commit message must always come from the user; `version-control-administrator` is the sole agent that asks for it.
- **No auto-push** — always confirm with the user before pushing to any remote.
- **No confirmations for read-only operations** — run searches, reads, and lookups silently.
- **Minimal output** — report results, not process narration.
- **Human review before all writes** — ticket comments/transitions and any external system edits require a preview + explicit approval.
- **Check prerequisites** before suggesting running the application (deps installed, env vars set, DB migrated, etc.).
- **All git write operations go through `version-control-administrator`** — no other agent may stage, commit, branch, push, or manage worktrees directly. This includes asking the user git-related questions (scope, message, files). Delegate immediately with no pre-screening.
- **No direct commits to `main`/`master`** — `version-control-administrator` MUST create a worktree before staging or committing any change in any repository, regardless of whether a formal ticket exists.

---

## Auto-Fix Rules

The following infrastructure operations are **safe to execute automatically** without asking for confirmation. When `agents-infrastructure-manager` detects any of these issues, it MUST fix them immediately rather than reporting them as warnings.

| Issue | Auto-Fix Command | Agent |
|---|---|---|
| `agents-memory-manager` DB missing | `bash .claude/scripts/mb-migrate.sh` | `agents-infrastructure-manager` |
| Hook not executable | `chmod +x .claude/hooks/*.sh` | `version-control-administrator` |
| `.context/` directory missing | `mkdir -p .context` | `agents-infrastructure-manager` |
| `.claude/memory-banks/` directory missing | `mkdir -p .claude/memory-banks` | `agents-infrastructure-manager` |
| `agents-infrastructure-manager` DB missing | `sqlite3 .claude/memory-banks/agents-infrastructure-manager` + schema init | `agents-infrastructure-manager` |

**Rule**: If a fix command is in this table, run it silently and report it as ℹ️ (Info) in the final status, not as ⚠️ (Warning). Only escalate to Warning or Broken if the fix itself fails.

---

## Session Initialization

The `.claude/hooks/load-memory-bank.sh` script runs at session start via `SessionStart` hook. It outputs:

- Active tickets (not archived), ordered by last updated
- Any relevant cache entries (e.g., cached ticket transitions or search results)

This context is injected at the top of the session so agents have immediate awareness of in-progress work.

**After session start**, the master-coordinator's first action is always to invoke `agents-infrastructure-manager` (Stage 0). This agent:
- Creates its own DB at `.claude/memory-banks/agents-infrastructure-manager` if it doesn't exist
- Checks all tools, hooks, memory banks, project structure, and env vars
- Auto-fixes safe issues (permissions, missing dirs)
- Reports environment status before any workflow proceeds

---

## Project: Agnostic Agent Builder

This repository is an **agnostic SDLC orchestration hub**. It does not contain application code itself — instead it provides the agent infrastructure, memory bank, and workflow tooling needed to plan, implement, review, test, and ship any number of independent component projects from a single Claude Code session.

Each component project lives in its own git worktree (isolated branch + directory) and is tracked as a ticket in the memory bank. The agents in this repo manage the full lifecycle across all components.

### Purpose

- **Multi-project SDLC management** — track and drive work across several unrelated components without mixing their code or history
- **Isolated worktrees per ticket** — every implementation branch lives at `../<repo-name>-worktrees/<TICKET-KEY>/`, keeping `main` clean
- **Persistent memory** — decisions, ADRs, workflows, and ticket state survive across sessions via the SQLite memory bank
- **Agnostic tech stack** — the orchestration layer is framework- and language-neutral; component projects can be Python, TypeScript, Java, or anything else

### Adding a New Component Project

1. Create a ticket via `ticket-administrator` (Jira, GitHub Issues, or local markdown).
2. Record the component's repo path, tech stack, and key decisions in the memory bank via `agents-memory-manager`.
3. Run the **End-to-End Ticket Implementation** workflow — the master coordinator will create a worktree, invoke the architecture advisor, implement, review, test, and open a PR.
4. Add a component entry below once the first PR is merged.

### Active Components

| Component | Repo | Ticket | Status |
|---|---|---|---|
| taulia-wco-agent | `../agnostic-agent-builder-worktrees/ait-1085/` | AIT-1085 | in_progress |

### Component Notes

Each component may have its own tech stack, run instructions, and env var requirements. These are captured in:

- `.context/<TICKET-KEY>/architecture-plan.md` — authoritative design + constraints
- `.context/<TICKET-KEY>/README.md` — component-specific run and deploy notes
- Memory bank category `architecture` — ADRs and key decisions per component
