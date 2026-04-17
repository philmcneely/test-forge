# Section: fetch-follow.md
# Loaded ONLY when FOLLOW=true. Contains Step 4b: fetch all linked Confluence
# pages, child Confluence pages, and extended Jira ticket graph.
# Do NOT load this file when FOLLOW=false.

---

## Step 4b: Confluence and extended context (--follow enabled)

You are reading this section because `FOLLOW=true`.

**First, count what will be fetched:**
- All Confluence pages linked to primary ticket + child stories
- All Jira tickets linked beyond the immediate family (parent + 12 children)

**Print before fetching:**
```
⚠️  --follow is enabled.
    Found: N Confluence pages, M additional linked tickets.
    This is a large context run. If it fails mid-generation, re-run without --follow
    and consult the linked pages manually.
    Proceeding...
```

**Then fetch in this order:**

1. All linked Confluence pages (primary ticket + child stories):
   `mcp__mcp-atlassian__confluence_get_page(page_id=PAGE_ID)`
   Include first 1000 chars of each page body as context.

2. Confluence child pages (up to 3 per linked page):
   `mcp__mcp-atlassian__confluence_get_page_children(parent_id=PAGE_ID, limit=3, include_content=true)`
   Include first 500 chars per child.

3. Additional linked Jira tickets beyond immediate family (up to 8):
   `mcp__mcp-atlassian__jira_get_issue(issue_key=LINKED_KEY, fields="summary,description,status")`
   Include summary + first 400 chars of description.

If any individual fetch fails → skip it, note the skip, continue with the rest.

If combined context exceeds ~40,000 tokens → note truncation in the document header and continue.
