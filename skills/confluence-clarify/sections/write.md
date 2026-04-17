## Step 5: Write the output file

Save to `<OUTPUT_DIR>/confluence-<SLUG>_clarify.md`:

```
confluence-<SLUG> — Clarification Questions & Assumptions
Source: <PAGE_TITLE>
URL: <CONFLUENCE_URL>
Generated: <date>
Round: <N>   ← increment if file already exists from a previous run

=== CLARIFICATION QUESTIONS ===

[questions]

=== ASSUMPTIONS ===

[assumptions]

=== SUGGESTED AC SKELETON ===

[Section 3 content]
```

**Round tracking:** if `confluence-<SLUG>_clarify.md` already exists, append a new dated section rather than overwriting. Increment the Round number. This preserves the history of clarification rounds as the spec evolves.

**Detecting the current round number:**
- If `confluence-<SLUG>_clarify.md` does not exist → this is Round 1.
- If the file exists: scan for all lines matching `^Round: (\d+)$`. Take the highest number found and add 1.
- If the file exists but contains no such line (e.g. manually edited or from an older version) → use Round 1 and print a warning: `⚠️ Could not detect prior round number in confluence-<SLUG>_clarify.md — starting at Round 1. Check the file for duplicate rounds.`

Confirm file path to user when done — print the full absolute path: `<cwd>/<OUTPUT_DIR>/confluence-<SLUG>_clarify.md`.

Then print:
```
💡 Done! Your output file is ready.
   VS Code / Copilot Chat: start a NEW chat thread before your next ticket —
   this keeps each ticket's context clean and prevents earlier results from
   interfering. Use the + New Conversation button in the Copilot Chat panel.
   Claude Code: run /clear (wipe context) or /compact (summarise and continue).
```

## Step 6: Post questions as a Confluence comment (--create only) or preview

**If CREATE=false (default dry run):**

Print:
```
========================================
DRY RUN — Step 6 Preview: Confluence Comment
Would POST to page: PAGE_TITLE (PAGE_ID)
----------------------------------------
Clarification Questions — Round N

  1. <question 1>
  2. <question 2>
  ...

Closing: "Full clarification document: confluence-SLUG_clarify.md"
         "To generate a ticket breakdown, run: /confluence-breakdown <URL>"
To post for real: /confluence-clarify <URL> --create
========================================
```

**If CREATE=true:**

**Double-submit guard** — fetch the most recent comment on the page. If that comment contains both `"[confluence-clarify]"` (the tool signature) and `"Round N"` (matching the current round number) and was posted within the last 5 minutes, print: `"Round N comment was just posted — skipping duplicate."` and stop. Checking for the tool signature prevents false positives from other users or tools posting comments that happen to contain "Round N". This guard does NOT block re-runs after the spec has been updated.

**MCP:** `mcp__mcp-atlassian__confluence_get_comments(page_id=PAGE_ID)` — check only the most recent comment.

**curl fallback:** `GET $JIRA_URL/wiki/rest/api/content/$PAGE_ID/child/comment?limit=1&expand=version` — check `version.when` and body.

**MCP post:**
```
mcp__mcp-atlassian__confluence_add_comment(
  page_id = PAGE_ID,
  body = "**Clarification Questions — Round N**\n\n[numbered question list]\n\nFull clarification document: confluence-SLUG_clarify.md\n\nTo generate a ticket breakdown from this spec, run: /confluence-breakdown <URL>\n[confluence-clarify]"
)
```

**curl fallback:** POST to `$JIRA_URL/wiki/rest/api/content/$PAGE_ID/child/comment` with storage format body.

Log the comment ID returned, or warning if none.
