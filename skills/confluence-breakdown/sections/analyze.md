## Step 4: Analyze scope and draft ticket breakdown

Read the full spec (primary page + child pages) and determine the appropriate ticket structure.

**Scope sizing rules:**
- Single focused feature or behaviour change → 1 Story (no epic unless `--parent` given)
- Multiple related features sharing a theme → 1 new Epic + N Stories
- Multiple unrelated features → N Stories; suggest grouping under existing or new epics
- `--parent` given → all stories nest under that epic; do NOT create a new epic

**For each ticket, draft:**

```
--- TICKET [N] ---
Type: Epic | Story | Task | Bug
Summary: [concise one-line summary — max 100 chars]
Description:
  [2-3 sentences describing what this ticket covers and why]

Acceptance Criteria:
  - [AC 1 — specific, testable]
  - [AC 2]
  - [AC 3]
  ...

Labels: [suggested labels based on spec content]
Components: [suggested components if determinable from spec]
Priority: P0 | P1 | P2 | P3
Parent: [EPIC-KEY if nesting under existing epic | "New Epic — Ticket N" if new | "None"]
Suggested next steps:
  - /jira-clarify <KEY> — testing clarification questions once ticket is created
  - /jira-test-gen <KEY> — full test document when ready
Notes: [dependencies, open questions, regulatory flags, anything ticket creator should know]
```

**Ordering:** Epic first (if new), then stories in dependency order.

**Minimum:** draft as many tickets as the scope warrants — do not artificially split or bundle.

**Regulatory flag:** if `regulatoryApprovals` is set in config and the spec touches any regulated area, flag each affected ticket with: `⚠️ Regulatory sign-off required: [list approvals]`
