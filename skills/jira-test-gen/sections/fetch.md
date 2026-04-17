# Section: fetch.md
# Loaded on every invocation. Contains Steps 2, 3, 4: fetch primary ticket,
# parent/epic, and linked child stories.
# Also contains the FOLLOW=false Confluence auto-fetch logic (always applies).

---

## Step 2: Fetch the primary ticket

**MCP:**
```
mcp__mcp-atlassian__jira_get_issue(
  issue_key = KEY,
  fields = "summary,description,status,priority,issuetype,labels,components,fixVersions,
            comment,issuelinks,subtasks,parent,attachment,reporter,
            customfield_10063,customfield_10144",
  comment_limit = 8
)
```

`customfield_10063` = Acceptance Criteria, `customfield_10144` = Acceptance Test — common Jira
custom fields. If either is non-null, include the value as AC content alongside the description.
If the fields don't exist on the ticket (null or absent), silently ignore them.

**curl fallback:**
```bash
TMPFILE=$(mktemp "${TMPDIR:-/tmp}/${KEY}_fetch_XXXXXX.json")
curl -s ${JIRA_SSL_NO_REVOKE:+--ssl-no-revoke} \
  -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/issue/$KEY?fields=summary,description,status,priority,issuetype,\
labels,components,fixVersions,comment,issuelinks,subtasks,parent,attachment,reporter,\
customfield_10063,customfield_10144" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"} \
  -o "$TMPFILE"
```

Extract: KEY, summary, status, priority, issue type, labels, components, fix versions,
reporter (name + accountId), numeric issue id, description (ADF → plain text), last 8 comments,
all issue links, all subtasks, parent key/summary.

If ticket not found (404) → tell user and stop.

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

---

## Step 3: Fetch parent / epic context

**MCP:** `mcp__mcp-atlassian__jira_get_issue(issue_key=PARENT_KEY, fields="summary,description,labels,components,fixVersions,issuelinks")`

**curl fallback:** same pattern as Step 2 with parent key.

---

## Step 4: Fetch linked child stories (up to 12)

Identify child/related story keys from the primary ticket's issue links, comments listing story keys,
and the parent's issue links. Limit to 12 most relevant.

**MCP:** `mcp__mcp-atlassian__jira_get_issue(issue_key=CHILD_KEY, fields="summary,description,status,fixVersions")`

Extract: summary, status, first 500 chars of description/AC.

---

## Step 4 — Confluence auto-fetch (FOLLOW=false, always applies)

After fetching child stories, scan for Confluence URLs in the ticket description, remote links,
and attachments.

**If FOLLOW=false but Confluence pages are found:**
- If exactly 1 Confluence page linked → fetch it automatically (bounded context, safe default):
  `mcp__mcp-atlassian__confluence_get_page(page_id=PAGE_ID)`
- If more than 1 Confluence page linked → print the following, then fetch ONLY the first page:

```
⚠️  Found N Confluence pages linked to this ticket. Only pulling the first one.
    To include all linked Confluence pages and extended ticket context, re-run with --follow:
    /jira-test-gen KEY --follow

    ⚠️  WARNING: --follow can pull a very large amount of context. On tickets with many
    linked pages and stories this may exceed the model's context window and fail mid-run.
    Use --follow only when you need the full picture and the ticket graph is not deep.
```

If `FOLLOW=true` → skip this block entirely; the full Confluence fetch is handled in `fetch-follow.md`.
