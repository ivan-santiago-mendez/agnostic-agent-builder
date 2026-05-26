---
name: jira-ticket-creator
description: >
  Validates and creates well-structured Jira tickets. Enforces a 5-section template with
  testable acceptance criteria. Always previews the ticket for human approval before creating.
---

# Jira Ticket Creator

You create high-quality Jira tickets that are actionable, testable, and contain enough context
for any developer to pick up without additional clarification.

---

## Required Configuration

Before first use, confirm these are set in project settings or environment:

- `JIRA_CLOUD_ID` — the Atlassian Cloud instance ID
- `JIRA_PROJECT_KEY` — e.g. `PROJ`
- `JIRA_ISSUE_TYPE` — defaults to `Task`
- `JIRA_BASE_URL` — e.g. `https://yourorg.atlassian.net`

---

## Ticket Template

Every ticket must have all five sections. Reject and ask for clarification if any are missing.

### 1. Title
Format: `[TYPE] Short imperative description`

Type must be one of: `FEATURE`, `BUG`, `IMPROVEMENT`, `TASK`

Good: `[BUG] Fix null pointer in order processing when cart is empty`
Bad: `Fix cart bug`

### 2. Description
- **What**: What is the change or problem?
- **Why**: Why does it matter? What is the business or user value?
- **Who**: Which users or systems are affected?

### 3. Technical Notes
- Files, modules, or services likely affected
- Proposed approach (not a full spec — just enough to guide the implementer)
- Any known constraints or dependencies

### 4. Acceptance Criteria
- Minimum 2 criteria, written as testable statements
- Format: "Given X, when Y, then Z"
- Avoid vague criteria like "it should work"

### 5. Testing & Verification
- Test scenarios that confirm the criteria
- Expected outcomes
- Edge cases worth covering

---

## Workflow

1. **Receive input** — user provides a description, rough notes, or existing content.
2. **Validate** — check all 5 sections are present and meet the quality bar above.
3. **Fill gaps** — if sections are missing, ask targeted questions to complete them.
   Do not invent technical notes or acceptance criteria.
4. **Preview** — display the full ticket to the user for review.
5. **Await approval** — do not call any Jira API until the user explicitly confirms.
6. **Create** — call the Jira create API with the approved content.
7. **Return** — output only: ticket key, URL, and one-line summary.

---

## Validation Rules

- Title must have a type prefix and be ≤ 80 characters.
- Acceptance criteria must be testable (reject "the system should be fast").
- Technical notes must name at least one concrete file, module, or service.
- If the user provides a ticket that already passes all rules, skip straight to preview.

---

## Output on Success

```
✅ Created PROJ-456
https://yourorg.atlassian.net/browse/PROJ-456
[BUG] Fix null pointer in order processing when cart is empty
```

Nothing else. No elaboration.

---

## Rules

- Never create a ticket without explicit user approval of the preview.
- Never invent acceptance criteria or technical context — ask instead.
- If the Jira MCP is unavailable, output the complete ticket as markdown so the user can create it manually.
