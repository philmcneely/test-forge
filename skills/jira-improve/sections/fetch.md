## Step 2: Fetch the primary ticket

**MCP path:**
```
mcp__mcp-atlassian__jira_get_issue(
  issue_key = KEY,
  fields = "summary,description,status,priority,issuetype,labels,components,fixVersions,comment,issuelinks,subtasks,parent,attachment,reporter,customfield_10063,customfield_10144",
  comment_limit = 5
)
```

`customfield_10063` = Acceptance Criteria (textarea), `customfield_10144` = Acceptance Test
(textarea). Both are common Jira custom fields — include them silently; if either is
non-null, treat its value as additional AC content alongside the description.

**curl fallback:**
```bash
TMPFILE=$(mktemp "${TMPDIR:-/tmp}/${KEY}_fetch_XXXXXX.json")
curl -s ${JIRA_SSL_NO_REVOKE:+--ssl-no-revoke} \
  -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/issue/$KEY?fields=summary,description,status,priority,issuetype,labels,components,fixVersions,comment,issuelinks,subtasks,parent,attachment,reporter,customfield_10063,customfield_10144" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"} \
  -o "$TMPFILE"
```

Extract:
- KEY, summary, status, priority, issue type, labels, components, fix versions
- Reporter displayName → `REPORTER_NAME`; accountId → `REPORTER_ACCOUNT_ID`
- Full description (ADF to plain text if using curl — see ADF helper below)
- Last 5 comments (author + body, max 400 chars each) — useful context for inferring intent
- All issue links with key and summary
- All subtasks with key, summary, and status
- Parent issue key and summary if present
- `customfield_10063` raw value → `AC_FIELD_1`
- `customfield_10144` raw value → `AC_FIELD_2`

Collect all AC content into a single list `ALL_ACS`:
1. Parse ACs from `customfield_10063` (if non-null)
2. Parse ACs from `customfield_10144` (if non-null)
3. Parse ACs from the description — look for sections labelled "Acceptance Criteria", "AC:", "ACs:",
   or bullet/numbered lists under a heading that contains "accept" or "criteria" (case-insensitive)
4. Deduplicate — if the same AC text appears in multiple sources, keep once

If `ALL_ACS` is empty after this, note: `⚠️ No acceptance criteria found in this ticket —
all ACs in the output will be INFERRED from the description.`

If the ticket is not found (404), tell the user and stop.

**ADF-to-text helper (curl path only):**
```python
def extract_text(node):
    if not isinstance(node, dict): return ''
    t = node.get('type', '')
    if t == 'text': return node.get('text', '')
    if t == 'hardBreak': return '\n'
    if t == 'inlineCard': return node.get('attrs', {}).get('url', '')
    parts = [extract_text(c) for c in node.get('content', [])]
    joined = ''.join(parts)
    if t in ('paragraph', 'heading', 'listItem'): return joined + '\n'
    if t in ('tableCell', 'tableHeader'): return joined + ' | '
    if t == 'tableRow': return joined + '\n'
    if t == 'table': return '\n' + joined
    if t == 'rule': return '\n---\n'
    return joined
```

## Step 3: Fetch parent / epic context (if parent exists)

**MCP path:**
```
mcp__mcp-atlassian__jira_get_issue(
  issue_key = PARENT_KEY,
  fields = "summary,description,labels,components,fixVersions,issuelinks,customfield_10063,customfield_10144"
)
```

**curl fallback:**
```bash
curl -s ${JIRA_SSL_NO_REVOKE:+--ssl-no-revoke} -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/issue/$PARENT_KEY?fields=summary,description,labels,components,fixVersions,issuelinks,customfield_10063,customfield_10144" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"}
```

Extract description and any ACs — add to context for inferring missing story-level ACs.
If parent fetch fails → skip silently, continue. If failure is a 403 (permission denied), note in
the document header: `⚠️ Parent epic <KEY> could not be fetched (permission denied) — inferred
ACs may be missing epic-level context.`
