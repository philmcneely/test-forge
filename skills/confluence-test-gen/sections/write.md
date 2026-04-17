# Section: write.md
# Loaded on every invocation. Contains Steps 7 (write output files) and
# Step 8 (post clarification questions as Confluence comment).

---

## Step 7: Write output files

**If `TESTDATA_ONLY=false`:** save `<OUTPUT_DIR>/<OUTPUT_FILE>`. Confirm full absolute path: `<cwd>/<OUTPUT_DIR>/<OUTPUT_FILE>`.
**If `NO_TESTDATA=false`:** save `<OUTPUT_DIR>/<TESTDATA_FILE>`. Confirm full absolute path: `<cwd>/<OUTPUT_DIR>/<TESTDATA_FILE>`.

Then print:
```
💡 Done! Your output file(s) are ready.
   VS Code / Copilot Chat: start a NEW chat thread before your next ticket —
   this keeps each ticket's context clean and prevents earlier results from
   interfering. Use the + New Conversation button in the Copilot Chat panel.
   Claude Code: run /clear (wipe context) or /compact (summarise and continue).
```

Always confirm both file paths to user in a single summary line:
```
✅ Written:
   confluence-<SLUG>_tests[_suffixes].md  — 12-section test document
   confluence-<SLUG>_testdata.md          — Test Data Catalogue (hand to data setup team)
```

(Omit the testdata line if `NO_TESTDATA=true`. Omit the tests line if `TESTDATA_ONLY=true`.)

---

## Step 8: Post clarification questions as Confluence comment (--create only) or preview

**Skip (and print one-line note) if `NO_CLARIFY=true` OR `TESTDATA_ONLY=true`:**
```
Step 8 skipped — no clarification questions generated (--no-clarify / --neg-only / --testdata-only).
```

**Dry-run preview (when `CREATE=false` AND `NO_CLARIFY=false`):**

Parse `Question:` lines from the output file, then print:
```
========================================
DRY RUN — Step 8 Preview: Confluence Comment
Would POST to: <CONFLUENCE_URL> (comments)
Page: PAGE_TITLE (PAGE_ID)
----------------------------------------
  1. <question 1>
  2. <question 2>
  ...
Closing: "Full test document: OUTPUT_FILE / Test Data Catalogue: TESTDATA_FILE"
To post for real: re-run with --create
========================================
```

**When `CREATE=true`:**

**Double-submit guard:** fetch the most recent comment on the page. If that comment contains both
`"[confluence-test-gen]"` (the tool signature) and `"Round N"` (matching the current round number)
and was posted within the last 5 minutes, log skip and stop. This guard does NOT block re-runs
after the spec has been updated.

**MCP post:**
```
mcp__mcp-atlassian__confluence_add_comment(
  page_id = PAGE_ID,
  body = "The automated test-case generator has produced the following clarification questions
for this spec:\n\n1. Q1\n2. Q2\n...\n\nFull test document: OUTPUT_FILE\n
Test Data Catalogue: TESTDATA_FILE\n[confluence-test-gen]"
)
```

**curl fallback:** POST to `$JIRA_URL/wiki/rest/api/content/$PAGE_ID/child/comment`

On 429 (rate limit): wait 10 seconds and retry once before logging failure.
On failure → log error, print questions to terminal, continue.
