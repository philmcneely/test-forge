## Step 0: Load project config (if present)

Look for `.test-gen.json` in the current working directory. If found, read it for project-specific domain context (platform targets, P0 rules, regulatory scope, etc.) — this helps generate more targeted questions. Missing keys are silently ignored.

**Parse flags:**
- Extract `JIRA_KEY` from ARGUMENTS (e.g. `PROJ-123`)
- Set `CREATE=true` if `--create` present, else `false`
- Derive `PROJECT_KEY` = everything before the first `-` in `JIRA_KEY`

**Derive output filename:**
- `OUTPUT_FILE=<JIRA_KEY>_clarify.md`

**Resolve output directory:**
- If `--output-dir <path>` is present → use that path as `OUTPUT_DIR`.
- Else if `.test-gen.json` in cwd has an `"outputDir"` key → use that value.
- Else → `OUTPUT_DIR=output` (a subdirectory of cwd).
- Create `OUTPUT_DIR` if it does not exist.

## Step 1: Resolve credentials and environment

**Preferred method: Atlassian MCP**

If `mcp__mcp-atlassian__jira_get_issue` is available, use it for all Jira reads.

**Fallback: curl + environment variables**

Read from environment:
- `JIRA_URL` → base URL (e.g. `https://yourcompany.atlassian.net`)
- `JIRA_USERNAME` → email address
- `JIRA_API_TOKEN` → Atlassian API token
- `SSL_CERT_FILE` → CA cert bundle path (corporate proxy only)
- `JIRA_SSL_NO_REVOKE` → set `true` to add `--ssl-no-revoke` (corporate proxy only)

If `JIRA_URL` is absent and MCP is unavailable, tell the user to configure one or the other and stop.

## Error handling

- Ticket not found (404): tell the user and stop
- Missing credentials: tell the user how to configure MCP or env vars and stop
- Comment POST fails: log the error, print the questions to the terminal so they are not lost, continue. On 429 (rate limit), wait 10 seconds and retry once before logging failure.
- Never print the API token value
- Re-runs are intentional and expected — each run generates fresh questions based on current ticket state and appends a new round to the output file
