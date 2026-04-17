## Step 0: Parse arguments and load config

- Extract `CONFLUENCE_URL` from ARGUMENTS
- Set `CREATE=true` if `--create` present, else `false`
- Look for `.test-gen.json` in cwd for domain context (platform targets, P0 rules, regulatory scope). Missing keys silently ignored.

**Derive output filename:**
- `SLUG` derived in Step 2 from page title.
- `OUTPUT_FILE=confluence-<SLUG>_clarify.md`

**Resolve output directory:**
- If `--output-dir <path>` is present → use that path as `OUTPUT_DIR`.
- Else if `.test-gen.json` in cwd has an `"outputDir"` key → use that value.
- Else → `OUTPUT_DIR=output` (a subdirectory of cwd).
- Create `OUTPUT_DIR` if it does not exist.

## Step 1: Resolve credentials

**Preferred: Atlassian MCP** — use `mcp__mcp-atlassian__confluence_get_page` if available.

**Fallback: curl + env vars:**
- `JIRA_URL` → base URL (used for both Jira and Confluence REST APIs — skills append `/wiki/...` for Confluence endpoints). If your Confluence is at a different host, set `CONFLUENCE_URL` instead; skills will prefer `CONFLUENCE_URL` over `JIRA_URL` for Confluence calls when both are set.
- `JIRA_USERNAME` → email
- `JIRA_API_TOKEN` → API token
- `SSL_CERT_FILE` → CA cert bundle (corporate proxy only)
- `JIRA_SSL_NO_REVOKE=true` → adds `--ssl-no-revoke`

If `JIRA_URL` absent and MCP unavailable → tell user to configure and stop.

## Error handling

- Page not found (404): tell user and stop
- Page ID cannot be extracted from URL: tell user expected format and stop
- Child page fetch fails: skip, note, continue
- Comment POST fails: log error, print questions to terminal so they are not lost. On 429 (rate limit), wait 10 seconds and retry once before logging failure.
- Missing credentials: tell user how to configure and stop
- Never print the API token value
- Re-runs are intentional and expected — each run generates fresh questions based on the current page state and appends a new round to the output file. Running --create again posts a new comment; previous round comments remain on the page.
