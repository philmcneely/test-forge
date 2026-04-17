## Step 0: Parse arguments and load config

- Extract `CONFLUENCE_URL` from ARGUMENTS
- Set `CREATE=true` if `--create` present, else `false`
- Set `PARENT_KEY` if `--parent <KEY>` present, else empty string
- Look for `.test-gen.json` in cwd. Read: `defaultProjectKey`, `projectContext`, `p0Rules`, `regulatoryApprovals`. Missing keys silently ignored.

**Derive output filename:**
- `SLUG` is derived later (Step 2) from page title. Placeholder for now.
- `OUTPUT_FILE=confluence-<SLUG>_tickets.md`

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

If `CREATE=true`, additionally ensure Jira write access is available (MCP `mcp__mcp-atlassian__jira_create_issue` or `JIRA_API_TOKEN` env var).

## Error handling

- Page not found (404): tell user and stop
- Page ID cannot be extracted from URL: tell user expected format and stop
- Child page fetch fails: skip, note, continue
- Parent epic fetch fails (--parent): warn user, ask whether to continue without parent context
- Jira creation fails (--create): log, continue with remaining tickets, report in summary
- Missing credentials: tell user how to configure and stop
- Never print the API token value
- Re-runs in dry mode: always safe
- Re-runs in --create mode: safe — the idempotency guard checks for existing tickets by summary before creating
