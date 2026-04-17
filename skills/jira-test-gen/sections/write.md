# Section: write.md
# Loaded on every invocation. Contains Steps 6, 7, and 8.

---

## Step 6: Save output file

Write the complete generated document to `<OUTPUT_DIR>/<OUTPUT_FILE>`. Print the full absolute path to the user: `<cwd>/<OUTPUT_DIR>/<OUTPUT_FILE>`.

Then print:
```
💡 Done! Your output file is ready.
   VS Code / Copilot Chat: start a NEW chat thread before your next ticket —
   this keeps each ticket's context clean and prevents earlier results from
   interfering. Use the + New Conversation button in the Copilot Chat panel.
   Claude Code: run /clear (wipe context) or /compact (summarise and continue).
```

---

## Step 7: Post clarification questions as Jira comment (--create only)

**Skip entirely if CREATE=false** — instead print the dry-run preview below.

**Skip (and print one-line note) if NO_CLARIFY=true or NEG_ONLY=true:**
```
Step 7 skipped — no clarification questions generated (--no-clarify / --neg-only).
```

**Dry-run preview (when CREATE=false AND NO_CLARIFY=false):**

Parse `Question:` lines from output file, then print:
```
========================================
DRY RUN — Step 7 Preview: Jira Comment
Would POST to: JIRA_URL/rest/api/3/issue/KEY/comment
Mention: @REPORTER_NAME (REPORTER_ACCOUNT_ID)
----------------------------------------
  1. <question 1>
  2. <question 2>
  ...
Closing: "Full test document: OUTPUT_FILE"
To post for real: re-run with --create
========================================
```

**When CREATE=true:**

**Double-submit guard:** fetch the most recent comment on the ticket. If that
comment contains both `"[jira-test-gen]"` (the tool signature) and `"Round N"`
(matching the current round number) and was posted within the last 5 minutes,
print: `"Round N comment was just posted — skipping duplicate."` and stop.
Checking for the tool signature prevents false positives from other users or
tools posting comments that happen to match. This guard does NOT block re-runs
after the ticket has been updated.

**MCP post:**
```
mcp__mcp-atlassian__jira_add_comment(
  issue_key = KEY,
  body = "@REPORTER_NAME — the automated test-case generator has produced the
following clarification questions for this ticket:\n\n1. Q1\n2. Q2\n...\n\n
Full test document: OUTPUT_FILE\n[jira-test-gen]"
)
```

**curl fallback:** ADF payload with mention node + ordered list. Write to
`$(mktemp "${TMPDIR:-/tmp}/${KEY}_comment_XXXXXX.json")`, POST, delete after.

Log comment ID returned, or warning if none.

On 429 (rate limit): wait 10 seconds and retry once before logging failure.

---

## Step 8: Create Zephyr Scale test cases (--create only)

**Skip entirely if NEG_ONLY=true** (Section 3 was not generated — nothing to parse):
```
Step 8 skipped — no Happy Path section generated with --neg-only.
```

**Skip entirely if CREATE=false** — instead print the dry-run preview below.

**Dry-run preview (when CREATE=false):**

Parse Section 3 from output file, then print:
```
========================================
DRY RUN — Step 8 Preview: Zephyr Scale Test Cases
Would POST to: ZEPHYR_BASE_URL/testcases
Project key: PROJECT_KEY
----------------------------------------
  1. [P0 -> Critical]  <scenario name>
  2. [P1 -> High]  <scenario name>
  ...
Total: N test cases would be created, each linked to KEY.
To create for real: re-run with --create
========================================
```

**When CREATE=true:**

**Token guard:** if `ZEPHYR_API_TOKEN` is unset → print setup instructions and skip.

**Idempotency guard:** fetch existing TC names for the project, then skip any
scenario whose name already exists. Name comparison is case-insensitive and
whitespace-normalised (collapse runs of whitespace, trim leading/trailing).
Truncate names at 255 characters before comparing. This ensures re-running
`--create` after minor edits does not create duplicate test cases.

**Parse Section 3** from output file. For each happy path scenario:
- Extract name, priority, steps (split on ` → ` for standard; extract
  Given/When/Then steps for Gherkin)
- Map priority: P0→Critical, P1→High, P2→Medium, P3→Low
- POST to `$ZEPHYR_BASE_URL/testcases`
- Sleep 0.3s between calls when creating more than 5
- Link each new TC back to `JIRA_ISSUE_ID`

On 403: token is missing Create/Edit scope — print instructions to re-generate.
On 429: sleep 10s, retry once; if still failing log and continue.

Print summary: created / skipped / failed counts.
