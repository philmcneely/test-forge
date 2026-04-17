## Step 2: Fetch the Confluence page

**Extract PAGE_ID from URL:**
- Modern: `.../pages/<PAGE_ID>/<Title>` — extract numeric segment
- Legacy display URL (`.../display/SPACEKEY/Page+Title`): resolve by searching for the page title in the space:
  - **MCP:** `mcp__mcp-atlassian__confluence_search(query="title=\"<PAGE_TITLE>\" AND space=\"<SPACE_KEY>\"")`  — extract `page_id` from the first result. If the search returns more than one result with the same title and running interactively, print the options and ask the user to confirm. If running headlessly, pick the most recently modified result and log a warning: `⚠️ Multiple pages matched title "<PAGE_TITLE>" — used most recently modified (<page_id>). Pass the full modern URL to override.`
  - **curl:** `GET $JIRA_URL/wiki/rest/api/content?spaceKey=<SPACE_KEY>&title=<ENCODED_TITLE>&expand=version` — if multiple results, pick `results[0]` (most recent) and log the same warning.
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

Derive `SLUG` — safe filename from page title (lowercase, alphanumeric + underscores, max 60 chars).

If page not found (404) or body empty → tell user and stop.

If `--parent` given → also fetch the parent epic for context:
**MCP:** `mcp__mcp-atlassian__jira_get_issue(issue_key=PARENT_KEY, fields="summary,description,labels,components,project")`
Extract project key from parent → use as `PROJECT_KEY`.

## Step 3: Fetch child pages (up to 8)

Fetch titles only first, then selectively pull content for spec-relevant children. A higher limit (8) is used here than in other skills because breakdown needs broader coverage to identify all stories — better to check more titles and skip the irrelevant ones than to miss a story due to an early cutoff.

**MCP (titles first):** `mcp__mcp-atlassian__confluence_get_page_children(parent_id=PAGE_ID, limit=8, include_content=false)`

For each child whose title suggests requirements or spec content (contains words like: spec, requirement, AC, acceptance, feature, user story, design, flow, behaviour — case insensitive), fetch its content:

**MCP (content):** `mcp__mcp-atlassian__confluence_get_page(page_id=CHILD_PAGE_ID)`

Skip children whose titles suggest implementation detail (words like: implementation, tech, schema, DB, database, architecture, infra). Limit to 4 content fetches maximum.

Include first 500 chars per qualifying child as supplementary context.

**curl fallback (titles):**
```bash
curl -s ${JIRA_SSL_NO_REVOKE:+--ssl-no-revoke} \
  -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/wiki/rest/api/content/$PAGE_ID/child/page?limit=8" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"}
```

Then fetch content for qualifying children individually via `$JIRA_URL/wiki/rest/api/content/$CHILD_ID?expand=body.storage`.

If fetch fails → skip silently. If failure is a 403, note in the output file header: `⚠️ Child page fetch failed (permission denied) — ticket breakdown may be missing context from child pages.`
