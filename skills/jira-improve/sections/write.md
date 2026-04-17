## Step 5: Write the output file

Save to `<OUTPUT_DIR>/<JIRA_KEY>_improved.md`.

If `<KEY>_improved.md` already exists, overwrite it — this skill is idempotent and always
produces the best current version based on the latest ticket state.

**File content:**
```
<KEY> — Improved Acceptance Criteria
Generated: <date>
Source ticket: <KEY> — <summary>
Status: <status> | Priority: <priority>

=== AC QUALITY ASSESSMENT ===

[Section 1: scored list of existing ACs]

=== REWRITTEN ACs (BDD FORMAT) ===

[Section 2: Given/When/Then for each AC, including ✅ ones reformatted]

=== INFERRED ACs (GAPS FILLED) ===

[Section 3: new ACs for gaps — every line inferred marked [INFERRED — confirm with PO]]

=== SUGGESTED DESCRIPTION UPDATE ===

[Section 4: cleaned-up description, or "No changes suggested" if already clear]
```

Confirm the file path to the user when done — print the full absolute path:
`<cwd>/<OUTPUT_DIR>/<JIRA_KEY>_improved.md`.

Then print a summary:
```
📋 AC Quality Summary for <KEY>:
   ✅ Testable:           <N>
   ⚠️  Vague:             <N>
   ❌  Missing/Untestable: <N>
   🆕 Inferred ACs added: <N>

Output: <full path to _improved.md>
```

Then print:
```
💡 Done! Your output file is ready.
   Review the [INFERRED — confirm with PO] tags — these need PO sign-off before use.
   To update the Jira ticket with these ACs: /jira-improve <KEY> --create
   VS Code / Copilot Chat: start a NEW chat thread before your next ticket.
   Claude Code: run /clear (wipe context) or /compact (summarise and continue).
```

## Step 6: Update Jira ticket (--create only) or preview

**If CREATE=false (default dry run):**

Print a diff-style preview of what would change:

```
========================================
DRY RUN — Step 6 Preview: Jira Update
Would UPDATE: $JIRA_URL/browse/$KEY
----------------------------------------
FIELDS THAT WOULD CHANGE:

[customfield_10063 — Acceptance Criteria]
  CURRENT:
    <existing AC field content, or "(empty)">
  PROPOSED:
    <full rewritten BDD ACs from Sections 2 + 3>

[description — if Section 4 has changes]
  CURRENT:
    <first 300 chars of current description>
  PROPOSED:
    <first 300 chars of proposed description>
----------------------------------------
To apply for real: /jira-improve $KEY --create
========================================
```

**If CREATE=true:**

Show the diff preview above first, then apply.

**What to update:**
- If `customfield_10063` was non-null or ACs were in the description: write the full rewritten
  BDD ACs (Sections 2 + 3 combined) to `customfield_10063`.
- If Section 4 has a suggested description update: update the description field.
- Do NOT update `customfield_10144` (Acceptance Test) — that field is for test case references,
  not AC definitions.

**MCP path:**
```
mcp__mcp-atlassian__jira_update_issue(
  issue_key = KEY,
  fields = {
    "customfield_10063": "<rewritten ACs as plain text>",
    "description": "<updated description if changed>"   ← omit if no description change
  }
)
```

**curl fallback:**
```bash
PAYLOAD=$(mktemp "${TMPDIR:-/tmp}/${KEY}_update_XXXXXX.json")
# Build JSON payload with fields to update
curl -s ${JIRA_SSL_NO_REVOKE:+--ssl-no-revoke} \
  -X PUT \
  -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"} \
  -d @"$PAYLOAD" \
  "$JIRA_URL/rest/api/3/issue/$KEY"
rm -f "$PAYLOAD"
```

**Validate:** on success, print: `✅ Jira ticket $KEY updated successfully.`
On failure, print the error, then print the full proposed ACs to the terminal so they are not lost.
On 429 (rate limit), wait 10 seconds and retry once before logging failure.
