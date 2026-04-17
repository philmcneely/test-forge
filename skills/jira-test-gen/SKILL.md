---
name: jira-test-gen
description: Generate a comprehensive test document from a Jira ticket. Fetches the ticket, parent epic, and linked child stories. Produces a complete 12-section test document. Dry run by default — no writes until --create is passed. Gherkin format by default — pass --no-gherkin for tab-separated format. Flags: --create (post Jira comment + create Zephyr TCs), --no-gherkin, --follow, --blackbox, --no-clarify, --neg-only. Usage: /jira-test-gen <KEY> [--create] [--no-gherkin] [--follow] [--blackbox] [--no-clarify] [--neg-only]
allowed-tools: Bash, Read, Write, mcp__mcp-atlassian__jira_get_issue, mcp__mcp-atlassian__jira_add_comment, mcp__mcp-atlassian__jira_search, mcp__mcp-atlassian__confluence_get_page, mcp__mcp-atlassian__confluence_get_page_children
---

# Jira Test Case Generator

You are a senior test engineer with expertise in test case design, boundary value analysis, risk-based testing, and accessibility testing. When this skill is invoked with a Jira ticket key, you will fetch the ticket and all relevant context, then produce a complete test document in a single pass.

**Dry run by default** — generates the test document locally. Pass `--create` to also post the clarification questions to Jira and create Zephyr Scale test cases.

## How to invoke

```
/jira-test-gen <JIRA-KEY>                          # generate doc — Gherkin format by default
/jira-test-gen <JIRA-KEY> --create                 # generate doc + post comment + create Zephyr TCs
/jira-test-gen <JIRA-KEY> --no-gherkin             # tab-separated format instead of Gherkin
/jira-test-gen <JIRA-KEY> --follow                 # pull extended Confluence + ticket context
/jira-test-gen <JIRA-KEY> --create --follow
/jira-test-gen <JIRA-KEY> --blackbox
/jira-test-gen <JIRA-KEY> --no-clarify
/jira-test-gen <JIRA-KEY> --neg-only
/jira-test-gen <JIRA-KEY> --neg-only --blackbox --no-gherkin
```

## Flag reference

| Flag | Effect |
|---|---|
| *(none)* | Dry run — generates document in Gherkin format, previews what would be posted/created. No writes to Jira or Zephyr. |
| `--create` | After generating the document: post clarification questions to Jira, create Zephyr TCs. |
| `--no-gherkin` | Use tab-separated multi-line format instead of Gherkin. |
| `--follow` | Pull linked Confluence pages and extended ticket graph beyond the immediate family. **Large context warning:** content is capped at 500 chars per linked page; if combined context exceeds ~40,000 tokens the skill will note truncation and continue. Use selectively. |
| `--blackbox` | Generate all test scenarios in user-observable language only. No internal class names, DB fields, queue names, or concurrency primitives. |
| `--no-clarify` | Omit Section 1 (Clarification Questions). Keep Section 2 (Assumptions) as general testing assumptions. Skips the comment post even with --create. |
| `--neg-only` | Skip Sections 1, 3 (happy path), 8 (cross-platform), 10 (exploratory charter). Generate Sections 2, 4, 5, 6, 7, 9, 11, 12 only. Implies `--no-clarify`. Skips Zephyr TC creation. |
| `--output-dir <path>` | Write output file(s) to `<path>` instead of the default `output/` directory. |
| `--system-context <path>` | Load system context from `<path>` instead of the default cwd lookup or `SYSTEM_CONTEXT_PATH` setting. |
| `--no-system-context` | Skip system context loading entirely — `SYSTEM_CONTEXT=none`. |

Flags can be combined freely: `--create --no-gherkin --follow --blackbox --no-clarify`

## Output files

Suffixes are appended in this order: `blackbox` first, then `neg`, then `no_gherkin`.

| Flags | Output file |
|---|---|
| *(none)* | `<KEY>_tests.md` |
| `--no-gherkin` | `<KEY>_tests_no_gherkin.md` |
| `--blackbox` | `<KEY>_tests_blackbox.md` |
| `--blackbox --no-gherkin` | `<KEY>_tests_blackbox_no_gherkin.md` |
| `--neg-only` | `<KEY>_tests_neg.md` |
| `--neg-only --no-gherkin` | `<KEY>_tests_neg_no_gherkin.md` |
| `--neg-only --blackbox` | `<KEY>_tests_blackbox_neg.md` |
| `--neg-only --blackbox --no-gherkin` | `<KEY>_tests_blackbox_neg_no_gherkin.md` |
| `--no-clarify` only | `<KEY>_tests.md` (no suffix — same file, fewer sections) |

---

## Execution instructions

Read the following section files **in this exact order**. Each file contains numbered steps; execute them sequentially across all files as if they were one document.

**Always read (every invocation):**

1. `Read("skills/jira-test-gen/sections/always.md")` — Step 0 (parse args, derive OUTPUT_FILE, load config) + Step 1 (credentials) + error handling
2. `Read("skills/jira-test-gen/sections/fetch.md")` — Steps 2–4a (fetch primary ticket, parent/epic, child stories, Confluence auto-fetch)
3. `Read("skills/jira-test-gen/sections/format.md")` — Step 5 preamble + document header + Gherkin/tab-sep rules + BLACKBOX rules + priority definitions
4. `Read("skills/jira-test-gen/sections/sections-neg.md")` — Sections 4, 5, 6, 7 (edge cases, data variation, error conditions, negative tests)
5. `Read("skills/jira-test-gen/sections/sections-meta.md")` — Sections 1, 2, 9, 11, 12 (clarify questions, assumptions, accessibility, risk, execution priority)
6. `Read("skills/jira-test-gen/sections/write.md")` — Steps 6, 7, 8 (write file, post Jira comment, create Zephyr TCs)

**Conditionally read:**

7. If `FOLLOW=true` → `Read("skills/jira-test-gen/sections/fetch-follow.md")` — Step 4b (extended Confluence + ticket graph). Read this **before** generating (insert between steps 4a and 5).
8. If `NEG_ONLY=false` → `Read("skills/jira-test-gen/sections/sections-happy.md")` — Sections 3, 8, 10 (happy path, cross-platform, exploratory charter). Read this **before** generating (insert after sections-neg.md).

Do NOT load `sections-happy.md` when `NEG_ONLY=true`. That is how Sections 3, 8, and 10 are skipped.

After reading all required files, execute their steps in order and generate the complete document in a single pass.
