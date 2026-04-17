# Section: fetch.md
# Loaded on every invocation. Contains Steps 2 (fetch page), 3 (parent),
# 4 (child check), and 4b (linked Jira tickets for Test Data Catalogue).

---

## Step 2: Fetch the Confluence page

**Extract PAGE_ID from URL:**
- Modern URL: `.../pages/<PAGE_ID>/...` — extract numeric segment after `/pages/`
- Legacy display URL (`.../display/SPACEKEY/Page+Title`): resolve by searching for the page title
  in the space:
  - **MCP:** `mcp__mcp-atlassian__confluence_search(query="title=\"<PAGE_TITLE>\" AND space=\"<SPACE_KEY>\"")`
    — extract `page_id` from the first result. If the search returns more than one result with the
    same title and running interactively, print the options and ask the user to confirm. If running
    headlessly, pick the most recently modified result and log a warning in the document header:
    `⚠️ Multiple pages matched title "<PAGE_TITLE>" — used most recently modified (<page_id>). Pass the full modern URL to override.`
  - **curl:** `GET $JIRA_URL/wiki/rest/api/content?spaceKey=<SPACE_KEY>&title=<ENCODED_TITLE>&expand=version`
    — if multiple results, pick `results[0]` (most recent) and log the same warning.
- Cannot extract and cannot resolve → tell user to use the full modern URL and stop

**MCP:** `mcp__mcp-atlassian__confluence_get_page(page_id=PAGE_ID)`

**curl fallback:**
```bash
CONF_TMPFILE=$(mktemp "${TMPDIR:-/tmp}/${PAGE_ID}_confluence_XXXXXX.json")
curl -s ${JIRA_SSL_NO_REVOKE:+--ssl-no-revoke} \
  -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/wiki/rest/api/content/$PAGE_ID?expand=body.storage,metadata.labels,version,ancestors" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"} \
  -o "$CONF_TMPFILE"
```

Extract: `PAGE_TITLE`, `SPACE_KEY`, `PAGE_ID`, `ANCESTORS` (breadcrumb), `LABELS`, body text (strip HTML).

Derive `SLUG` from PAGE_TITLE (lowercase, alphanumeric + underscores, max 60 chars). Update
`OUTPUT_FILE` and `TESTDATA_FILE` now that SLUG is known.

**While processing the page body, extract all Jira issue keys** (pattern: `[A-Z][A-Z0-9_]+-\d+`)
found in the text — milestone tables, linked tickets, requirement IDs. Store as `JIRA_KEYS_FOUND`.
Deduplicate. Limit to 6. Skip any key that is clearly part of an example, code block, or placeholder
(e.g. surrounded by backticks or inside a code fence). In Step 4b, if a key returns 404, skip it
silently — false positive keys from the regex will not fail the skill.

If page not found (404) or body empty → tell user and stop.

---

## Step 3: Fetch parent page (always — one level up)

Extract the immediate parent page ID from the `ANCESTORS` array returned in Step 2 (the last entry
is the direct parent). If a parent exists:

**MCP:** `mcp__mcp-atlassian__confluence_get_page(page_id=PARENT_PAGE_ID)`

Include the parent page title and first 500 chars of its body as background context.
On failure → skip silently, note in document header.

If no parent exists (page is at space root) → skip silently.

---

## Step 4: Check for child pages (always) — fetch only if --include-children

Always check whether child pages exist, regardless of the `--include-children` flag.

**MCP:** `mcp__mcp-atlassian__confluence_get_page_children(parent_id=PAGE_ID, limit=5, include_content=false)`

**If `INCLUDE_CHILDREN=false` and child pages exist:** print advisory (do NOT stop — just print and continue):

```
ℹ️  Found N child page(s) under this spec:
      · <child title 1>
      · <child title 2>
      ...
    Child pages are not included by default (they may contain implementation detail rather than spec content).
    To include them, re-run with --include-children:
    /confluence-test-gen <URL> --include-children [other flags]
```

**If `INCLUDE_CHILDREN=true`:** re-fetch with content included:
`mcp__mcp-atlassian__confluence_get_page_children(parent_id=PAGE_ID, limit=5, include_content=true)`
Include first 500 chars per child. Note in document header: `Child pages fetched: N (titles...)`.
If combined context exceeds ~40,000 tokens, note truncation in document header and continue.

**If no child pages exist:** skip silently.

---

## Step 4b: Fetch linked Jira tickets (for Test Data Catalogue)

**Skip entirely if `NO_TESTDATA=true`.**

For each key in `JIRA_KEYS_FOUND` (up to 6):

**MCP:** `mcp__mcp-atlassian__jira_get_issue(issue_key=KEY, fields="summary,description,issuetype,status,components", comment_limit=0)`

**curl fallback:**
```bash
curl -s ${JIRA_SSL_NO_REVOKE:+--ssl-no-revoke} \
  -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/issue/$KEY?fields=summary,description,issuetype,status,components" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"}
```

Extract: summary, description text, components, status. Use to supplement field rules and acceptance
criteria in the catalogue. On any individual failure → skip that ticket, continue.
