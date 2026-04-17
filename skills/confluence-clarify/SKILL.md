---
name: confluence-clarify
description: Fetch a Confluence spec page and generate clarification questions and assumptions targeted at the spec author. Supports multiple rounds — re-run after the spec is updated to surface new gaps. Dry run by default — writes file and previews the comment. Pass --create to post as a Confluence comment. Usage: /confluence-clarify <CONFLUENCE-URL> [--create]
allowed-tools: Bash, Read, Write, mcp__mcp-atlassian__confluence_get_page, mcp__mcp-atlassian__confluence_get_page_children, mcp__mcp-atlassian__confluence_search, mcp__mcp-atlassian__confluence_add_comment, mcp__mcp-atlassian__confluence_get_comments
---

# Confluence Clarify

You are a senior test engineer and requirements analyst. When this skill is invoked with a Confluence page URL, you will fetch the spec, generate clarification questions and assumptions, write them to a local file, and preview the Confluence comment.

**Dry run by default** — nothing is posted to Confluence unless `--create` is passed. Safe to re-run repeatedly as the spec evolves — each run is tracked as a new round and appends to the output file.

**Designed for multiple rounds.** Re-run after the spec author updates the page — each run generates fresh questions based on the current page content, acknowledges what has changed since the last round, and posts a new comment. It does not replace or suppress previous comments.

## How to invoke

```
/confluence-clarify <CONFLUENCE-URL>           # dry run — generates file + previews comment
/confluence-clarify <CONFLUENCE-URL> --create  # posts the comment to Confluence
```

## Flag reference

| Flag | Effect |
|---|---|
| *(none)* | Dry run — generates `confluence-<slug>_clarify.md`, prints preview of Confluence comment. Nothing posted. |
| `--create` | Posts the clarification questions as a Confluence comment on the spec page. Safe to re-run — each run posts a new round. |

## Output file

`confluence-<SLUG>_clarify.md`

---

## Sections

Read the following section files in order. Each file contains the detailed instructions for that phase of execution.

**Always load — read all of these now:**

1. Read `sections/always.md` — parse flags, resolve credentials, error handling
2. Read `sections/fetch.md` — fetch Confluence page and child pages
3. Read `sections/generate.md` — generate clarification questions and assumptions
4. Read `sections/write.md` — write output file and post Confluence comment (--create only)

All four sections are always loaded for this skill — there are no conditional sections. The `--create` flag affects behaviour within `write.md` but does not change which sections are loaded.
