# Section: always.md
# Loaded on every invocation. Contains Step 0 (argument parsing + config load),
# Step 1 (credentials), and all error handling rules.

---

## Step 0: Parse arguments and load config

**Parse ARGUMENTS:**
- Extract `KEY` — the Jira issue key (e.g. `PROJ-123`)
- Set `CREATE=true` if `--create` present, else `false`
- Set `GHERKIN=false` if `--no-gherkin` present, else `true` (Gherkin is the default)
- Set `FOLLOW=true` if `--follow` present, else `false`
- Set `BLACKBOX=true` if `--blackbox` present, else `false`
- Set `NO_CLARIFY=true` if `--no-clarify` present, else `false`
- Set `NEG_ONLY=true` if `--neg-only` present, else `false`
- If `NEG_ONLY=true` → also set `NO_CLARIFY=true` (neg-only always implies no-clarify)

**Derive OUTPUT_FILE:**
- Start with base: `${KEY}_tests`
- If `BLACKBOX=true` → append `_blackbox`
- If `NEG_ONLY=true` → append `_neg`
- If `GHERKIN=false` → append `_no_gherkin`
- Append `.md`
- Exception: if `NO_CLARIFY=true` AND `BLACKBOX=false` AND `NEG_ONLY=false` AND `GHERKIN=true` → `${KEY}_tests.md` (no suffix)

**Load project config:**
Look for `.test-gen.json` in the current working directory. If found, read it for domain context
(platforms, P0 rules, regression risks, fix version patterns, etc.). Missing keys silently ignored.
If not found, proceed with generic generation.

**Resolve output directory:**
- If `--output-dir <path>` is present → use that path as `OUTPUT_DIR`.
- Else if `.test-gen.json` has an `"outputDir"` key → use that value as `OUTPUT_DIR`.
- Else → `OUTPUT_DIR=output` (a subdirectory of cwd).
- Create `OUTPUT_DIR` if it does not exist (e.g. `mkdir -p "$OUTPUT_DIR"`).
- Set full output path: `<OUTPUT_DIR>/<OUTPUT_FILE>`.

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

## Step 1: Resolve credentials and environment

**Preferred: Atlassian MCP** — if `mcp__mcp-atlassian__jira_get_issue` is available, use it for all Jira reads.

**Fallback: curl + env vars:**
- `JIRA_URL` → base URL
- `JIRA_USERNAME` → email
- `JIRA_API_TOKEN` → API token
- `SSL_CERT_FILE` → CA cert bundle (corporate proxy only)
- `JIRA_SSL_NO_REVOKE=true` → adds `--ssl-no-revoke` (corporate proxy only)

If `JIRA_URL` absent and MCP unavailable → tell user to configure one or the other and stop.

**Zephyr Scale (Step 8, skipped if absent):**
- `ZEPHYR_API_TOKEN` → Bearer token
- `ZEPHYR_BASE_URL` → defaults to `https://api.zephyrscale.smartbear.com/v2`

**Resolve additionally:**
- `PROJECT_KEY` → `${KEY%%-*}` (e.g. `PROJ-123` → `PROJ`)
- `REPORTER_NAME`, `REPORTER_ACCOUNT_ID` → from Step 2 response
- `JIRA_ISSUE_ID` → numeric `id` from Step 2 response

---

## Error handling

- Ticket not found (404): tell user and stop
- Missing credentials: tell user how to configure MCP or env vars and stop
- Child story fetch fails: skip, note in document header, continue
- Confluence fetch fails (--follow): skip that page, note skip, continue
- Comment POST fails: log error, print questions to terminal so they are not lost, continue to Step 8.
  On 429 (rate limit), wait 10 seconds and retry once before logging failure.
- Zephyr 403: token missing Create/Edit scope — re-generate
- Zephyr 429: sleep 10s, retry once; if still failing log and continue
- Never print the API token value
- Re-runs with --create are expected — re-running after a ticket is updated generates fresh questions
  and a new comment. The double-submit guard prevents accidental duplicate posts within the same session only.
