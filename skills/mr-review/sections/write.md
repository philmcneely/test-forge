# Section: write.md
# Loaded on every invocation. Contains Steps 6 (write output file) and
# Step 7 (post review as MR/PR comment + optional Jira comment).

---

## Step 6: Write the output file

Save to `<OUTPUT_DIR>/<OUTPUT_FILE>`. Confirm full absolute path to user: `<cwd>/<OUTPUT_DIR>/<OUTPUT_FILE>`.

Then print:
```
💡 Done! Your output file is ready.
   VS Code / Copilot Chat: start a NEW chat thread before your next ticket —
   this keeps each ticket's context clean and prevents earlier results from
   interfering. Use the + New Conversation button in the Copilot Chat panel.
   Claude Code: run /clear (wipe context) or /compact (summarise and continue).
```

---

## Step 7: Post review as MR/PR comment (--create only)

**Skip entirely if CREATE=false** — instead print the dry-run preview below.

**Dry-run preview (when CREATE=false):**
```
========================================
DRY RUN — Step 7 Preview: MR Comment
Would POST to: <MR_URL> (comments)
----------------------------------------
Summary of what would be posted:

  Overall: <readiness emoji + label>
  <summary sentence>

  Code quality issues: N (X critical, Y warnings)
  AC coverage: N/N addressed (or: no ACs provided)
  Missing tests: N flagged

  Full review: <OUTPUT_FILE>
To post for real: re-run with --create
========================================
```

**When CREATE=true:**

**GitLab post:**
```bash
curl -s --ssl-no-revoke \
  -X POST \
  -H "Authorization: Bearer $GITLAB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"<COMMENT_BODY>\"}" \
  "${GITLAB_BASE}/api/v4/projects/${PROJECT_PATH}/merge_requests/${MR_IID}/notes" \
  ${SSL_CERT_FILE:+--cacert "$SSL_CERT_FILE"}
```

**GitHub post:**
```bash
curl -s \
  -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"<COMMENT_BODY>\"}" \
  "https://api.github.com/repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments"
```

**Comment body format** (markdown):
```
**MR Review — [mr-review]**

**Overall: <emoji> <label>**

<summary paragraph>

**Code quality issues:** N (X critical, Y warnings)
**AC coverage:** N/N addressed | No ACs provided
**Missing tests flagged:** N

**Blockers:**
- [blocker 1, if any]
- None

**Key questions for author:**
1. [Q1]
2. [Q2]
...

Full review document: <OUTPUT_FILE>
[mr-review]
```

**If `--jira` given AND CREATE=true:** also post a brief testing comment on the Jira ticket:

**MCP:**
```
mcp__mcp-atlassian__jira_add_comment(
  issue_key = JIRA_KEY,
  body = "MR review completed for <MR_URL>.\n\nOverall: <emoji> <label>\n\nSee full review: <OUTPUT_FILE>\n[mr-review]"
)
```

Log comment IDs returned, or warnings if none.
