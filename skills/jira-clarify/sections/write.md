## Step 5: Write the output file

Save to `<OUTPUT_DIR>/<JIRA-KEY>_clarify.md`.

**Round tracking:** if `<KEY>_clarify.md` already exists from a previous run, append a new dated section rather than overwriting. Increment the Round number. This preserves the full history of clarification rounds as the ticket evolves.

**Detecting the current round number:**
- If `<KEY>_clarify.md` does not exist → this is Round 1.
- If the file exists: scan for all lines matching `^Round: (\d+)$`. Take the highest number found and add 1.
- If the file exists but contains no such line (e.g. manually edited or from an older version) → use Round 1 and print a warning: `⚠️ Could not detect prior round number in <KEY>_clarify.md — starting at Round 1. Check the file for duplicate rounds.`

Content (first run creates the file; subsequent runs append):
```
<KEY> — Clarification Questions & Assumptions
Generated: <date>
Round: <N>

=== CLARIFICATION QUESTIONS ===

[Section 1 content]

=== ASSUMPTIONS ===

[Section 2 content]

=== SUGGESTED AC SKELETON ===

[Section 3 content]
```

Confirm the file path to the user when done — print the full absolute path: `<cwd>/<OUTPUT_DIR>/<JIRA_KEY>_clarify.md`.

Then print:
```
💡 Done! Your output file is ready.
   VS Code / Copilot Chat: start a NEW chat thread before your next ticket —
   this keeps each ticket's context clean and prevents earlier results from
   interfering. Use the + New Conversation button in the Copilot Chat panel.
   Claude Code: run /clear (wipe context) or /compact (summarise and continue).
```

## Step 6: Post questions as a Jira comment (--create only) or preview

**If CREATE=false (default dry run):**

Parse the questions from the output file (lines starting with `Question:`), then print:

```
========================================
DRY RUN — Step 6 Preview: Jira Comment
Would POST to: $JIRA_URL/rest/api/3/issue/$KEY/comment
Mention: @$REPORTER_NAME ($REPORTER_ACCOUNT_ID)
----------------------------------------
Comment that would be posted (Round N):

@$REPORTER_NAME — clarification questions for this ticket (Round N):

  1. <question 1>
  2. <question 2>
  ...

Full clarification document: $KEY_clarify.md
----------------------------------------
Total questions: <N>
To post for real: /jira-clarify $KEY --create
========================================
```

**If CREATE=true:**

**Double-submit guard** — fetch the most recent comment on the ticket. If that comment contains both `"[jira-clarify]"` (the tool signature) and `"Round N"` (matching the current round number) and was created within the last 5 minutes, print: `"Round N comment was just posted — skipping duplicate."` and stop. Checking for the tool signature prevents false positives from other users or tools posting comments that happen to contain "Round N". This guard does NOT block re-runs after the ticket has been updated.

**MCP path (recency check):**
```
mcp__mcp-atlassian__jira_get_issue(issue_key = KEY, fields = "comment", comment_limit = 5)
```
Check only the most recent comment: if its body contains `"[jira-clarify]"` AND `"Round N"` and was created within the last 5 minutes, skip. Otherwise proceed.

**curl fallback:**
```bash
curl -s ${JIRA_SSL_NO_REVOKE:+--ssl-no-revoke} \
  -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"} \
  "$JIRA_URL/rest/api/3/issue/$KEY/comment?maxResults=5&orderBy=-created"
```

**Post the comment:**

**MCP path:**

Build the comment body as markdown, mentioning the reporter by name:

```
@REPORTER_NAME — clarification questions for this ticket (Round N):

1. <Q1>
2. <Q2>
...

Full clarification document: KEY_clarify.md
[jira-clarify]
```

```
mcp__mcp-atlassian__jira_add_comment(
  issue_key = KEY,
  body = "<comment body above>"
)
```

**curl fallback:**

Build an ADF JSON payload with:
- A paragraph containing a `mention` node (`id`: REPORTER_ACCOUNT_ID, `text`: `@REPORTER_NAME`) followed by `"— clarification questions for this ticket (Round N):"`
- An `orderedList` of the questions
- A closing paragraph: `"Full clarification document: KEY_clarify.md"`

Write payload to `$(mktemp "${TMPDIR:-/tmp}/${KEY}_comment_XXXXXX.json")`, POST to `$JIRA_URL/rest/api/3/issue/$KEY/comment`, delete temp file after.

**Validate:** log the comment ID returned, or log a warning if no ID was returned. Either way, continue.
