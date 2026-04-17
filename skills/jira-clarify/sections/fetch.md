## Step 2: Fetch the primary ticket

**MCP path:**
```
mcp__mcp-atlassian__jira_get_issue(
  issue_key = KEY,
  fields = "summary,description,status,priority,issuetype,labels,components,fixVersions,comment,issuelinks,subtasks,parent,attachment,reporter,customfield_10063,customfield_10144",
  comment_limit = 8
)
```

`customfield_10063` = Acceptance Criteria (textarea), `customfield_10144` = Acceptance Test (textarea). Both are common Jira custom fields — include them silently; if either is non-null, treat its value as additional AC content alongside the description.

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
- Last 8 comments (author + body, max 600 chars each)
- All issue links with key and summary
- All subtasks with key, summary, and status
- Parent issue key and summary if present

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
  fields = "summary,description,labels,components,fixVersions,issuelinks"
)
```

**curl fallback:**
```bash
curl -s ${JIRA_SSL_NO_REVOKE:+--ssl-no-revoke} -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/issue/$PARENT_KEY?fields=summary,description,labels,components,fixVersions,issuelinks" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"}
```

Extract description and any additional context that helps surface requirement gaps.
If parent fetch fails → skip silently, continue. If failure is a 403 (permission denied), note in the document header: `⚠️ Parent epic <KEY> could not be fetched (permission denied) — questions may be missing epic-level context.`
