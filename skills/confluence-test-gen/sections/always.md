# Section: always.md
# Loaded on every invocation. Contains Step 0 (argument parsing + config load),
# Step 1 (credentials), and error handling rules.

---

## Step 0: Parse arguments and load config

**Parse ARGUMENTS:**
- Extract `CONFLUENCE_URL` — the first positional argument
- Set `CREATE=true` if `--create` present, else `false`
- Set `GHERKIN=false` if `--no-gherkin` present, else `true` (Gherkin is the default)
- Set `BLACKBOX=true` if `--blackbox` present, else `false`
- Set `NO_CLARIFY=true` if `--no-clarify` present, else `false`
- Set `NEG_ONLY=true` if `--neg-only` present, else `false`
- Set `INCLUDE_CHILDREN=true` if `--include-children` present, else `false`
- Set `NO_TESTDATA=true` if `--no-testdata` present, else `false`
- Set `TESTDATA_ONLY=true` if `--testdata-only` present, else `false`
- If `NEG_ONLY=true` → also set `NO_CLARIFY=true`
- If `TESTDATA_ONLY=true` → also set `NO_CLARIFY=true`

**Derive OUTPUT_FILE (test document):**
- Start with base: `confluence-<SLUG>_tests`
- If `BLACKBOX=true` → append `_blackbox`
- If `NEG_ONLY=true` → append `_neg`
- If `GHERKIN=false` → append `_no_gherkin`
- Append `.md`
- Exception: if `NO_CLARIFY=true` AND `BLACKBOX=false` AND `NEG_ONLY=false` AND `GHERKIN=true` → `confluence-<SLUG>_tests.md` (no suffix)

**Set TESTDATA_FILE:** always `confluence-<SLUG>_testdata.md`

(SLUG is derived in Step 2 after the page title is fetched. Until then, treat SLUG as a placeholder.)

**Load project config:**
Look for `.test-gen.json` in the current working directory. If found, read it for domain context
(platforms, P0 rules, regression risks, fix version patterns, etc.). Missing keys silently ignored.
If not found, proceed with generic generation.

**Resolve output directory:**
- If `--output-dir <path>` is present → use that path as `OUTPUT_DIR`.
- Else if `.test-gen.json` has an `"outputDir"` key → use that value as `OUTPUT_DIR`.
- Else → `OUTPUT_DIR=output` (a subdirectory of cwd).
- Create `OUTPUT_DIR` if it does not exist (e.g. `mkdir -p "$OUTPUT_DIR"`).
- Set `OUTPUT_FILE` and `TESTDATA_FILE` to `<OUTPUT_DIR>/<filename>` (prepend the dir).

**Load system context:**
- If `--no-system-context` is present → set `SYSTEM_CONTEXT=none`, skip this step entirely.
- Otherwise resolve the path using this priority order:
  1. `--system-context <path>` flag value (if provided)
  2. `SYSTEM_CONTEXT_PATH` env var (set via `env` block in `.claude/settings.json` — workspace, or `~/.claude/settings.json` — user)
  3. `system-context.md` in cwd (legacy default)
- If a path was resolved, read that file and store its contents as `SYSTEM_CONTEXT`.
  This file describes the platform's integration map (entry points, call chain, downstream services,
  cross-system trigger rules). Include it as active context throughout generation — particularly
  when identifying integration risks in Sections 6, 7, 11, and 12.
- If the resolved file does not exist → warn "system-context file not found at <path>" and set `SYSTEM_CONTEXT=none`.
- If no path was resolved and no cwd file exists → set `SYSTEM_CONTEXT=none` and proceed without it.

---

## Step 1: Resolve credentials

**Preferred: Atlassian MCP** — if `mcp__mcp-atlassian__confluence_get_page` is available, use it
for all Confluence reads and writes. Use `mcp__mcp-atlassian__jira_get_issue` for any linked Jira tickets.

**Fallback: curl + env vars:**
- `JIRA_URL` → base URL (used for both Jira and Confluence REST APIs — skills append `/wiki/...` for
  Confluence endpoints). If your Confluence is at a different host, set `CONFLUENCE_URL` instead;
  skills will prefer `CONFLUENCE_URL` over `JIRA_URL` for Confluence calls when both are set.
- `JIRA_USERNAME` → email
- `JIRA_API_TOKEN` → API token
- `SSL_CERT_FILE` → CA cert bundle (corporate proxy only)
- `JIRA_SSL_NO_REVOKE=true` → adds `--ssl-no-revoke`

If `JIRA_URL` absent and MCP unavailable → tell user to configure one or the other and stop.

---

## Error handling

- Page not found (404) → tell user and stop
- Cannot extract PAGE_ID from URL → tell user expected format and stop
- Body empty after extraction → tell user and stop
- Missing credentials → tell user to configure MCP or env vars and stop
- Parent page fetch fails → skip silently, note in document header
- Child page check fails → skip silently, omit advisory
- Child page content fetch fails (--include-children) → skip, note in header, continue
- Jira ticket fetch fails (Step 4b) → skip that ticket, note in catalogue header, continue
- Comment POST fails → log error, print questions to terminal, continue.
  On 429 (rate limit), wait 10 seconds and retry once before logging failure.
- Never print the API token value
- Re-runs with --create are expected — re-running after the spec is updated generates fresh questions
  and a new comment. The double-submit guard prevents accidental duplicate posts within the same session only.
