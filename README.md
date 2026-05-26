# agnostic-agent-builder

**A multi-agent SDLC orchestration hub built on Claude Code.**

This repository contains no application code. It provides the agent infrastructure, memory bank, and workflow tooling to plan, implement, review, test, and ship independent component projects — all from a single Claude Code session.

---

## How It Works

You describe work. The agents coordinate it.

A `master-coordinator` agent receives your request and delegates to 13 specialist agents covering architecture, implementation, review, security, testing, documentation, version control, and ticketing. Every session starts with a mandatory environment health check. No code is written without an approved architecture plan.

```
You → master-coordinator
         ├── agents-infrastructure-manager  (Stage 0: env gate)
         ├── architecture-advisor           (Stage 2: design gate)
         ├── code-implementer               (inside isolated worktree)
         ├── code-reviewer
         ├── security-auditor
         ├── test-generator
         ├── documentation-writer
         ├── version-control-administrator  (all git writes)
         ├── ticket-administrator           (Jira / GitHub / Linear)
         └── agents-memory-manager          (all DB reads/writes)
```

---

## Quick Start

### Prerequisites

- Claude Code CLI installed and authenticated
- `sqlite3` available on the system `PATH`
- Git 2.x+

### Setup

```bash
# Clone the repo
git clone <repo-url> agnostic-agent-builder
cd agnostic-agent-builder

# Initialize the memory bank
bash .claude/scripts/mb-migrate.sh

# Start a Claude Code session
claude
```

On the first message of every session, the system automatically runs the infrastructure health check and loads active ticket context. No manual setup is required beyond the steps above.

### Running the Coordinator

```bash
bash run-coordinator.sh
```

---

## Project Structure

```
agnostic-agent-builder/
├── CLAUDE.md                        <- canonical system rules (read by Claude)
├── run-coordinator.sh               <- session entry point
├── .claude/
│   ├── agents/                      <- 14 specialist agent definitions
│   │   ├── master-coordinator.md
│   │   ├── agents-infrastructure-manager.md
│   │   ├── architecture-advisor.md
│   │   ├── version-control-administrator.md
│   │   ├── code-implementer.md
│   │   ├── code-reviewer.md
│   │   ├── security-auditor.md
│   │   ├── test-generator.md
│   │   ├── documentation-writer.md
│   │   ├── ticket-administrator.md
│   │   ├── agents-memory-manager.md
│   │   ├── memory-bank-retriever.md
│   │   ├── local-system-administrator.md
│   │   └── jira-ticket-creator.md
│   ├── hooks/
│   │   ├── session-init.sh          <- resets session sentinel
│   │   ├── load-memory-bank.sh      <- injects active tickets at session start
│   │   └── first-turn-guard.sh      <- forces infra check on first message
│   ├── scripts/
│   │   └── mb-migrate.sh            <- memory bank schema initialization
│   ├── memory-banks/                <- SQLite DBs (gitignored)
│   └── settings.json
└── .context/                        <- per-ticket context folders
    └── <TICKET-KEY>/
        ├── implementation-plan.md
        ├── orchestration-state.json
        └── notes.md
```

---

## Agents

| Agent | Stage | Responsibility |
|---|---|---|
| `master-coordinator` | — | Orchestrates multi-step workflows; delegates all work; tracks state |
| `agents-infrastructure-manager` | Stage 0 | Environment health gate — reports HEALTHY / DEGRADED / BROKEN |
| `architecture-advisor` | Stage 2 | Design review + ADR production; issues APPROVED / NEEDS_REVISION / BLOCKED verdict |
| `version-control-administrator` | — | Central VCS gateway — the only agent that runs git write operations |
| `code-implementer` | Stage 4 | Implements tickets inside isolated worktrees; requires an APPROVED plan |
| `code-reviewer` | Stage 5 | Code quality review |
| `security-auditor` | Stage 6 | Deep security scan |
| `test-generator` | Stage 7 | Test spec generation |
| `documentation-writer` | Stage 8 | Doc creation and maintenance |
| `ticket-administrator` | — | Full ticket lifecycle (Jira, GitHub Issues, Linear, local markdown) |
| `agents-memory-manager` | — | Single entry point for all memory bank reads and writes |
| `memory-bank-retriever` | — | Low-level SQLite interface; called only by agents-memory-manager |
| `local-system-administrator` | — | Cross-platform shell command execution |
| `jira-ticket-creator` | — | Structured Jira ticket creation |

---

## Key Concepts

### Memory Bank

A SQLite knowledge store at `.claude/memory-banks/`. Persists across sessions and holds:

| Table | Purpose |
|---|---|
| `documents` | Workflows, templates, ADRs, standards, agent docs |
| `tickets` | Active and archived ticket metadata with context paths |
| `cache` | Short-lived key/value entries (transitions, search results) |

All reads and writes go through `agents-memory-manager`. No agent queries the DB directly.

Initialized with:

```bash
bash .claude/scripts/mb-migrate.sh
```

### Worktrees

Each ticket gets an isolated git worktree so `main` is never touched during active development.

| Item | Pattern |
|---|---|
| Directory | `../agnostic-agent-builder-worktrees/<TICKET-KEY>/` |
| Branch | `feat/<TICKET-KEY>` or `fix/<TICKET-KEY>` or `chore/<TICKET-KEY>` |

Worktrees are created by `version-control-administrator` at Stage 3 of the end-to-end workflow and removed only after the PR is confirmed merged.

```bash
# List all active worktrees
git worktree list

# Remove after PR merge
git worktree remove ../agnostic-agent-builder-worktrees/PROJ-123
git branch -d feat/PROJ-123
```

### Session Lifecycle

Three hooks run automatically via Claude Code's hook system:

1. `session-init.sh` — resets the first-turn sentinel at session start
2. `load-memory-bank.sh` — queries the DB and injects active tickets as session context
3. `first-turn-guard.sh` — intercepts the first user message and forces both the infrastructure health check and memory load before any response is generated

### Workflows

#### Quality Gate

```
[1/5] agents-infrastructure-manager   env health check
[2/5] code-reviewer                   code quality
[3/5] security-auditor                security scan
[4/5] test-generator                  test coverage
[5/5] documentation-writer            doc update
```

#### End-to-End Ticket Implementation

```
[1/8]  agents-infrastructure-manager   env gate
[2/8]  agents-memory-manager           load context
[3/8]  architecture-advisor            design gate (must return APPROVED)
[4/8]  version-control-administrator   create worktree + branch
[5/8]  code-implementer                implement in worktree
[6/8]  code-reviewer + security-auditor  review gates
[7/8]  test-generator                  generate tests
[8/8]  documentation-writer + version-control-administrator  docs + PR
```

---

## Guardrails

| Rule | Detail |
|---|---|
| No auto-commits | Always ask for the commit message; never generate one unilaterally |
| No auto-push | Confirm with the user before pushing to any remote |
| No implementation without APPROVED plan | `code-implementer` will not run without an architecture gate verdict of APPROVED |
| All git writes through VCA | `version-control-administrator` is the only agent that stages, commits, branches, or pushes |
| All DB access through MAM | `agents-memory-manager` is the only entry point to the memory bank SQLite |
| All shell commands through LSA | `local-system-administrator` handles all OS-level operations |
| Human review before external writes | Ticket comments, transitions, and any external system edits require a preview and explicit approval |

---

## Auto-Fix Behaviors

The infrastructure manager automatically resolves the following issues without prompting:

| Issue | Fix |
|---|---|
| Memory bank DB missing | `bash .claude/scripts/mb-migrate.sh` |
| Hook files not executable | `chmod +x .claude/hooks/*.sh` |
| `.context/` directory missing | `mkdir -p .context` |
| `.claude/memory-banks/` directory missing | `mkdir -p .claude/memory-banks` |

---

## Active Components

| Component | Repo                   | Ticket   | Status |
|-----------|------------------------|----------|---|
| Example   | `../project/XXX-1234/` | XXX-1234 | in_progress |

To add a new component: create a ticket via `ticket-administrator`, record the repo path and tech stack in the memory bank via `agents-memory-manager`, then run the end-to-end ticket implementation workflow.

---

## Further Reading

- `CLAUDE.md` — canonical system rules and agent delegation triggers
- `.claude/agents/master-coordinator.md` — full orchestration workflow definition
- `.claude/agents/agents-infrastructure-manager.md` — environment health check spec
- `.claude/agents/architecture-advisor.md` — architecture gate and ADR format
