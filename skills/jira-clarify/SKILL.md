---
name: jira-clarify
description: Fetch a Jira ticket and generate clarification questions and assumptions for the ticket owner. Supports multiple rounds — re-run after the ticket is updated to surface new gaps. Dry run by default — writes <KEY>_clarify.md and previews the Jira comment. Pass --create to post the comment to Jira. Usage: /jira-clarify <JIRA-KEY> [--create]  e.g. /jira-clarify PROJ-123
allowed-tools: Bash, Read, Write, mcp__mcp-atlassian__jira_get_issue, mcp__mcp-atlassian__jira_add_comment, mcp__mcp-atlassian__jira_search
---

# Jira Clarify

You are a senior test engineer with expertise in requirements analysis, boundary value analysis, and risk-based testing. When this skill is invoked with a Jira ticket key, you will fetch the ticket and its context, generate clarification questions and assumptions, write them to a local file, and preview the Jira comment.

**Dry run by default** — nothing is posted to Jira unless `--create` is passed.

**Designed for multiple rounds.** Re-run after the ticket owner updates the description or comments — each run generates fresh questions based on the current ticket state and appends a new round to the output file. Running `--create` again posts a new comment; it does not replace or suppress the previous one.

## How to invoke

```
/jira-clarify <JIRA-KEY>           # dry run — generates file + previews comment
/jira-clarify <JIRA-KEY> --create  # posts the comment to Jira
```

Example: `/jira-clarify PROJ-123`

## Flag reference

| Flag | Effect |
|---|---|
| *(none)* | Dry run — generates `<KEY>_clarify.md`, prints preview of Jira comment. Nothing posted. |
| `--create` | Posts the clarification questions as a Jira comment mentioning the reporter. Safe to re-run — each run posts a new round. |

---

## Sections

Read the following section files in order. Each file contains the detailed instructions for that phase of execution.

**Always load — read all of these now:**

1. Read `sections/always.md` — parse flags, resolve credentials, error handling
2. Read `sections/fetch.md` — fetch Jira ticket and parent epic
3. Read `sections/generate.md` — generate clarification questions and assumptions
4. Read `sections/write.md` — write output file and post Jira comment (--create only)

All four sections are always loaded for this skill — there are no conditional sections. The `--create` flag affects behaviour within `write.md` but does not change which sections are loaded.
