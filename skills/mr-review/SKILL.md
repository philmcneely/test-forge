---
name: mr-review
description: Review a GitLab or GitHub MR/PR — fetches the diff, linked Jira ticket, and Confluence spec, then produces code quality analysis, testing clarification questions, risk assessment, and a targeted test document covering only what changed. Dry run by default. Usage: /mr-review <MR-URL> [--jira KEY] [--confluence URL] [--create] [--no-gherkin] [--blackbox]
allowed-tools: Bash, Read, Write, mcp__mcp-atlassian__jira_get_issue, mcp__mcp-atlassian__jira_add_comment, mcp__mcp-atlassian__jira_search, mcp__mcp-atlassian__confluence_get_page, mcp__mcp-atlassian__confluence_get_page_children
---

# MR / PR Review

You are a senior test engineer and code reviewer with expertise in test case design, code quality analysis, security, and risk-based testing. When this skill is invoked with a GitLab or GitHub MR/PR URL, you fetch the diff and all available context, then produce a unified review document covering code quality, testing gaps, targeted test cases, and risk assessment.

**Dry run by default** — generates the review document locally. Pass `--create` to post the review as a comment on the MR/PR and optionally on the linked Jira ticket.

**Works with or without Jira/Confluence.** Link them for a richer cross-referenced review, or just run against the MR URL alone.

## How to invoke

```
/mr-review <MR-URL>
/mr-review <MR-URL> --jira KEY
/mr-review <MR-URL> --confluence URL
/mr-review <MR-URL> --jira KEY --confluence URL
/mr-review <MR-URL> --create
/mr-review <MR-URL> --jira KEY --confluence URL --create
/mr-review <MR-URL> --no-gherkin
/mr-review <MR-URL> --blackbox
```

Examples:
```
/mr-review https://gitlab.company.net/group/repo/-/merge_requests/622
/mr-review https://github.com/org/repo/pull/123 --jira PROJ-456
/mr-review https://gitlab.company.net/group/repo/-/merge_requests/622 --jira COMPUTJC-943 --confluence https://company.atlassian.net/wiki/spaces/WD/pages/581700153/My+Spec
```

You can also paste a raw diff directly into the chat after invoking — the skill will detect it and use it as input.

## Flag reference

| Flag | Effect |
|---|---|
| *(none)* | Dry run — fetch MR/diff, generate review document locally. Nothing posted. |
| `--jira KEY` | Also fetch the linked Jira ticket for AC, description, and reporter context. Cross-reference ticket AC against the diff. |
| `--confluence URL` | Also fetch the linked Confluence spec page. Cross-reference spec requirements against the diff. |
| `--create` | Post the review summary as a comment on the MR/PR. If `--jira` given, also post a testing comment on the Jira ticket. |
| `--no-gherkin` | Use tab-separated multi-line format instead of Gherkin for test sections. |
| `--blackbox` | Observable language only — no internal class names, DB field names, or implementation details in test scenarios. |

Flags can be combined freely: `--jira KEY --confluence URL --create --blackbox`

## Output files

| Flags | Output file |
|---|---|
| *(none)* | `mr-<MR-ID>_review.md` |
| `--no-gherkin` | `mr-<MR-ID>_review_no_gherkin.md` |
| `--blackbox` | `mr-<MR-ID>_review_blackbox.md` |
| `--blackbox --no-gherkin` | `mr-<MR-ID>_review_blackbox_no_gherkin.md` |

`MR-ID` is derived from the URL — the numeric MR/PR identifier (e.g. `622` from `.../merge_requests/622`).

---

## Execution instructions

Read the following section files **in this exact order**. Each file contains numbered steps;
execute them sequentially across all files as if they were one document.

**Always read (every invocation):**

1. `Read("skills/mr-review/sections/always.md")` — Step 0 (parse args, derive OUTPUT_FILE, load config) + error handling
2. `Read("skills/mr-review/sections/fetch.md")` — Step 1 (credentials), Steps 2a–4 (MR API fetch, pasted diff fallback, Jira, Confluence)
3. `Read("skills/mr-review/sections/format.md")` — Step 5 preamble + document header + testing callout box + BLACKBOX rules + priorities
4. `Read("skills/mr-review/sections/sections.md")` — Sections 1–10 (all sections; mr-review has no conditional sections)
5. `Read("skills/mr-review/sections/write.md")` — Steps 6 (write file), 7 (post MR comment + optional Jira comment)

**mr-review has no conditional section files.** All sections are always generated for every invocation.
The only flags that affect content are:
- `--blackbox` → applies language rules defined in format.md to all scenarios in sections.md
- `--no-gherkin` → changes table format in sections.md Section 7
- `--jira` → enables Section 4 (AC Coverage Analysis) in sections.md
- `--confluence` → enables Section 5 (Spec Compliance) in sections.md
- `--create` → enables the actual MR/Jira comment POST in write.md (otherwise dry-run preview)

After reading all 5 files, execute their steps in order and generate the complete review document in a single pass.
