# Section: fetch.md
# Loaded on every invocation. Contains Steps 1 (credentials), 2a (MR/PR API fetch),
# 2b (pasted diff fallback), 3 (Jira ticket), and 4 (Confluence spec).

---

## Step 1: Resolve credentials

**GitLab API (primary — GitLab is the standard SCM here; GitHub support is experimental):**

Try the following env vars in order:
1. `GITLAB_TOKEN` — preferred variable name; set this in `~/.claude/settings.json` under `env`
2. `GITLAB_PAT` — fallback alias; checked if `GITLAB_TOKEN` is not set

For the API auth header, use `Authorization: Bearer <token>`. This is what self-hosted corporate
GitLab instances require. Do NOT use `PRIVATE-TOKEN` — it does not work on all instances.

Other GitLab vars:
- `GITLAB_URL` → base URL of the self-hosted GitLab instance (e.g. `https://gitlab.yourcompany.com`)
  — **required for self-hosted instances, not needed for gitlab.com**. Extract from MR_URL as fallback.
- `SSL_CERT_FILE` → CA cert bundle path (corporate proxy / self-signed cert only)
- `JIRA_SSL_NO_REVOKE=true` → adds `--ssl-no-revoke` to all curl calls (corporate proxy only)

**Required GitLab token scopes:**
- `read_api` — fetch MR metadata, diff, and comments (required for all mr-review runs)
- `read_repository` — access repository content if needed for context
- `api` — required only if `--create` is passed (to POST MR comments)

Minimum for dry run (no `--create`): **`read_api`**
Minimum for `--create`: **`read_api` + `api`**

**GitHub API (experimental — not the primary SCM):**
- `GITHUB_TOKEN` → personal access token with `repo` scope (or fine-grained: `pull_requests: read` + `contents: read`)
- For `--create`: also needs `pull_requests: write`

**Jira MCP / env vars (if `--jira` given):**
- Prefer `mcp__mcp-atlassian__jira_get_issue` if available
- Fallback: `JIRA_URL` + `JIRA_USERNAME` + `JIRA_API_TOKEN`

**Confluence MCP / env vars (if `--confluence` given):**
- Prefer `mcp__mcp-atlassian__confluence_get_page` if available
- Fallback: same `JIRA_URL` base

**If MR_URL is provided but no API token is set AND no MCP equivalent:**
```
⚠️  No GitLab token found.
    Set GITLAB_PAT in ~/.claude/settings.json under "env":

    {
      "env": {
        "GITLAB_PAT": "your-token-here",
        "GITLAB_URL": "https://gitlab.yourcompany.com"
      }
    }

    Token needs read_api scope (+ api scope for --create).
    Create one at: https://gitlab.yourcompany.com/-/user_settings/personal_access_tokens

    Or paste the diff from the MR's Changes tab directly into chat.
```
Wait for the user to paste a diff. If content is pasted, proceed with Step 2b.
If no token and nothing pasted → tell user to set the token or paste the diff, then stop.

**If a 401 is returned:**
```
⚠️  GitLab token rejected (401). Your token may have expired.
    Create a new one at: https://gitlab.yourcompany.com/-/user_settings/personal_access_tokens
    Then update GITLAB_PAT in ~/.claude/settings.json and re-run.

    Or paste the diff from the MR's Changes tab directly into chat.
```
Stop. Do not retry with a different header format.

---

## Step 2a: Fetch the MR/PR via API

**GitLab — extract project path and MR IID from URL:**
Pattern: `<GITLAB_BASE>/<GROUP>/<PROJECT>/-/merge_requests/<IID>`
- `PROJECT_PATH` = URL-encode `<GROUP>/<PROJECT>` (replace `/` with `%2F`)
- `MR_IID` = `<IID>`
- `GITLAB_BASE` = from `GITLAB_URL` env var, or extract scheme+host from `MR_URL`

**Fetch MR metadata:**
```bash
curl -s --ssl-no-revoke \
  -H "Authorization: Bearer $GITLAB_TOKEN" \
  "${GITLAB_BASE}/api/v4/projects/${PROJECT_PATH}/merge_requests/${MR_IID}" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"}
```
Extract: `title`, `description`, `state`, `author.name`, `target_branch`, `source_branch`,
`created_at`, `web_url`, linked issue references in description.

**Fetch MR diff:**
```bash
curl -s --ssl-no-revoke \
  -H "Authorization: Bearer $GITLAB_TOKEN" \
  "${GITLAB_BASE}/api/v4/projects/${PROJECT_PATH}/merge_requests/${MR_IID}/diffs" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"}
```
Extract: for each changed file — `old_path`, `new_path`, `diff` content (`+`/`-` lines),
`new_file`, `deleted_file`, `renamed_file`.

Cap total diff content at ~6000 lines. If larger, process the first 6000 lines and note truncation:
`⚠️ Diff truncated at 6000 lines — review the full diff at <MR_URL> for complete coverage.`

**Fetch MR comments/discussions (last 10, max 300 chars each):**
```bash
curl -s --ssl-no-revoke \
  -H "Authorization: Bearer $GITLAB_TOKEN" \
  "${GITLAB_BASE}/api/v4/projects/${PROJECT_PATH}/merge_requests/${MR_IID}/notes?per_page=20" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"}
```

**GitHub (for GitHub URLs):**
- MR metadata: `GET https://api.github.com/repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>`
- Diff: `GET https://api.github.com/repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/files`
- Comments: `GET https://api.github.com/repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments`
- Use `Authorization: Bearer $GITHUB_TOKEN` header

If fetch fails (non-200) → print error, ask user to paste the diff, continue.

---

## Step 2b: Pasted diff fallback

If the user has pasted a diff into the chat (or if API fetch failed), use the pasted content
directly as the diff input. No API calls needed — proceed with the pasted text as `DIFF_CONTENT`.

Detect pasted diff by looking for lines starting with `diff --git`, `+++`, `---`, `@@`, or `+`/`-` prefix lines.

If fewer than 20 meaningful diff lines found → warn:
`⚠️  Very little diff content detected (<N> lines). Review may be sparse.` and continue.

---

## Step 3: Fetch Jira ticket context (if --jira given)

**MCP path:**
```
mcp__mcp-atlassian__jira_get_issue(
  issue_key = JIRA_KEY,
  fields = "summary,description,status,priority,issuetype,labels,components,comment,issuelinks,reporter,subtasks,parent",
  comment_limit = 5
)
```

Extract: summary, description/ACs, reporter name + accountId, status, labels, components,
parent key/summary, last 5 comments. Use to cross-reference ACs against what the diff changes.

If fetch fails → skip, note in document header:
`⚠️ Jira ticket JIRA_KEY could not be fetched — review proceeds without ticket context.`

If Jira key found in MR description but `--jira` not passed → print:
```
ℹ️  Found Jira key <KEY> in MR description. To cross-reference ticket ACs against this diff, re-run with:
    /mr-review <MR_URL> --jira <KEY>
```

---

## Step 4: Fetch Confluence spec context (if --confluence given)

**MCP path:** `mcp__mcp-atlassian__confluence_get_page(page_id=PAGE_ID)`

Extract PAGE_ID from the Confluence URL (numeric segment after `/pages/`).

Include page title and first 1500 chars of body. Use to check whether the diff implements
what the spec requires and flag spec requirements with no corresponding code change.

If fetch fails → skip, note in document header.
