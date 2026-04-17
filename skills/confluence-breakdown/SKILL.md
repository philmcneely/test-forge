---
name: confluence-breakdown
description: Analyze a Confluence spec page, determine the appropriate Jira ticket breakdown (epic + stories, or multiple stories), and draft all tickets. Dry run by default — writes confluence-<slug>_tickets.md without creating anything in Jira. Pass --create to create tickets (checks for existing tickets by summary first to prevent duplicates). Pass --parent <EPIC-KEY> to nest stories under an existing epic. Usage: /confluence-breakdown <CONFLUENCE-URL> [--create] [--parent <EPIC-KEY>]
allowed-tools: Bash, Read, Write, mcp__mcp-atlassian__confluence_get_page, mcp__mcp-atlassian__confluence_get_page_children, mcp__mcp-atlassian__confluence_search, mcp__mcp-atlassian__jira_create_issue, mcp__mcp-atlassian__jira_get_issue, mcp__mcp-atlassian__jira_get_project_issues_metadata, mcp__mcp-atlassian__jira_search
---

# Confluence Breakdown

You are a senior test engineer and requirements analyst. When this skill is invoked with a Confluence page URL, you will fetch the spec, analyze its scope, and produce a draft Jira ticket breakdown. By default this is a dry run — nothing is created in Jira unless `--create` is passed.

Run `/confluence-clarify` first to surface and resolve spec gaps before running this skill.

## How to invoke

```
/confluence-breakdown <CONFLUENCE-URL>
/confluence-breakdown <CONFLUENCE-URL> --create
/confluence-breakdown <CONFLUENCE-URL> --parent <EPIC-KEY>
/confluence-breakdown <CONFLUENCE-URL> --create --parent <EPIC-KEY>
```

## Flag reference

| Flag | Effect |
|---|---|
| *(none)* | Dry run — draft tickets written to file, nothing created in Jira |
| `--create` | Create the drafted tickets in Jira (checks for existing tickets by summary first — safe to re-run) |
| `--parent <KEY>` | Nest all stories under this existing epic; do not create a new epic |

## Output files

| Mode | Files written |
|---|---|
| Dry run | `confluence-<SLUG>_tickets.md` |
| `--create` | `confluence-<SLUG>_tickets.md` (updated with created/skipped keys) |

---

## Sections

Read the following section files in order. Each file contains the detailed instructions for that phase of execution.

**Always load — read all of these now:**

1. Read `sections/always.md` — parse flags, resolve credentials, error handling
2. Read `sections/fetch.md` — fetch Confluence page and child pages
3. Read `sections/analyze.md` — analyze scope and draft ticket breakdown
4. Read `sections/write.md` — write output file and create tickets in Jira (--create only)

All four sections are always loaded for this skill — there are no conditional sections. The `--create` and `--parent` flags affect behaviour within the sections but do not change which sections are loaded.
