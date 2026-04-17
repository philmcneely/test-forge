---
name: confluence-test-gen
description: Generate a comprehensive test document from a Confluence spec page. Fetches the page and its parent page (one level up) for context. Child pages are NOT fetched by default — pass --include-children to include them. Produces a complete 12-section test document plus a Test Data Catalogue (Section 13 + separate _testdata.md file). Dry run by default — no writes until --create is passed. Gherkin format by default — pass --no-gherkin for tab-separated format. Flags: --create (post clarification questions as Confluence comment), --no-gherkin, --blackbox, --no-clarify, --neg-only, --include-children, --no-testdata, --testdata-only. Usage: /confluence-test-gen <CONFLUENCE-URL> [--create] [--no-gherkin] [--blackbox] [--no-clarify] [--neg-only] [--include-children] [--no-testdata] [--testdata-only]
allowed-tools: Bash, Read, Write, mcp__mcp-atlassian__confluence_get_page, mcp__mcp-atlassian__confluence_get_page_children, mcp__mcp-atlassian__confluence_search, mcp__mcp-atlassian__confluence_add_comment, mcp__mcp-atlassian__jira_get_issue
---

# Confluence Test Case Generator

You are a senior test engineer with expertise in test case design, boundary value analysis, risk-based testing, and accessibility testing. When this skill is invoked with a Confluence page URL, you will fetch the spec and its parent page for background context, then produce a complete test document and a Test Data Catalogue in a single pass. Child pages are not fetched by default. Optionally posts clarification questions as a comment on the source Confluence page.

**Dry run by default** — generates files locally. Pass `--create` to also post the clarification questions as a Confluence comment.

## How to invoke

```
/confluence-test-gen <URL>
/confluence-test-gen <URL> --create
/confluence-test-gen <URL> --no-gherkin
/confluence-test-gen <URL> --blackbox
/confluence-test-gen <URL> --blackbox --create
/confluence-test-gen <URL> --no-clarify
/confluence-test-gen <URL> --neg-only
/confluence-test-gen <URL> --include-children
/confluence-test-gen <URL> --testdata-only
/confluence-test-gen <URL> --neg-only --blackbox --no-gherkin
/confluence-test-gen <URL> --include-children --blackbox --create
```

## Flag reference

| Flag | Effect |
|---|---|
| *(none)* | Dry run — fetch page + parent, generate 12-section test doc + Test Data Catalogue in Gherkin format. No writes to Confluence. |
| `--create` | After generating: post clarification questions as a Confluence comment on the spec page. |
| `--no-gherkin` | Use tab-separated multi-line format instead of Gherkin. |
| `--blackbox` | Observable language only — no internal class/DB/queue names or concurrency primitives. |
| `--no-clarify` | Omit Section 1 (Clarification Questions). Keep Section 2 as general testing assumptions. Skips comment post even with --create. |
| `--neg-only` | Generate Sections 2, 4, 5, 6, 7, 9, 11, 12 only. Implies `--no-clarify`. |
| `--include-children` | Also fetch up to 5 child pages as additional spec context. Each child capped at 500 chars; if combined context exceeds ~40,000 tokens the skill will note truncation and continue. |
| `--no-testdata` | Skip the Test Data Catalogue entirely (Section 13 and `_testdata.md` file). |
| `--testdata-only` | Generate only the Test Data Catalogue (`_testdata.md`). Skip all 12 test sections and the comment post. Implies `--no-clarify`. |
| `--system-context <path>` | Load system context from `<path>` instead of the default cwd lookup or `SYSTEM_CONTEXT_PATH` setting. |
| `--no-system-context` | Skip system context loading entirely — `SYSTEM_CONTEXT=none`. |

Flags can be combined freely: `--create --no-gherkin --blackbox --no-clarify --neg-only --include-children`

## Output files

SLUG = page title sanitised (lowercase, alphanumeric + underscores, max 60 chars).
Suffixes are appended in this order: `blackbox` first, then `neg`, then `no_gherkin`.

Every run (unless `--no-testdata` or `--testdata-only`) produces **two files**:

| File | Contents |
|---|---|
| `confluence-<SLUG>_tests[_suffixes].md` | 12-section test document + Section 13 summary |
| `confluence-<SLUG>_testdata.md` | Full Test Data Catalogue (data request list) |

Test document filename suffixes:

| Flags | Test document file |
|---|---|
| *(none)* | `confluence-<SLUG>_tests.md` |
| `--no-gherkin` | `confluence-<SLUG>_tests_no_gherkin.md` |
| `--blackbox` | `confluence-<SLUG>_tests_blackbox.md` |
| `--blackbox --no-gherkin` | `confluence-<SLUG>_tests_blackbox_no_gherkin.md` |
| `--neg-only` | `confluence-<SLUG>_tests_neg.md` |
| `--neg-only --no-gherkin` | `confluence-<SLUG>_tests_neg_no_gherkin.md` |
| `--neg-only --blackbox` | `confluence-<SLUG>_tests_blackbox_neg.md` |
| `--neg-only --blackbox --no-gherkin` | `confluence-<SLUG>_tests_blackbox_neg_no_gherkin.md` |
| `--no-clarify` only | `confluence-<SLUG>_tests.md` (no suffix) |

---

## Execution instructions

Read the following section files **in this exact order**. Each file contains numbered steps;
execute them sequentially across all files as if they were one document.

**Always read (every invocation):**

1. `Read("skills/confluence-test-gen/sections/always.md")` — Step 0 (parse args, derive OUTPUT_FILE + TESTDATA_FILE, load config) + Step 1 (credentials) + error handling
2. `Read("skills/confluence-test-gen/sections/fetch.md")` — Steps 2–4b (fetch page, parent, child check, linked Jira tickets)
3. `Read("skills/confluence-test-gen/sections/format.md")` — Step 5 preamble + document header + Gherkin/tab-sep rules + BLACKBOX rules + priority definitions
4. `Read("skills/confluence-test-gen/sections/sections-neg.md")` — Sections 4, 5, 6, 7 (edge cases, data variation, error conditions, negative tests)
5. `Read("skills/confluence-test-gen/sections/sections-meta.md")` — Sections 1, 2, 9, 11, 12, 13 summary (clarify questions, assumptions, accessibility, risk, execution priority, testdata summary)
6. `Read("skills/confluence-test-gen/sections/write.md")` — Steps 7 (write files), 8 (post comment)

**Conditionally read:**

7. If `NEG_ONLY=false` → `Read("skills/confluence-test-gen/sections/sections-happy.md")` — Sections 3, 8, 10 (happy path, cross-platform, exploratory charter). Read **before** generating (insert after sections-neg.md).
8. If `NO_TESTDATA=false` → `Read("skills/confluence-test-gen/sections/testdata.md")` — Step 6 (generate full Test Data Catalogue). Read **before** generating (insert after sections-meta.md).

Do NOT load `sections-happy.md` when `NEG_ONLY=true`.
Do NOT load `testdata.md` when `NO_TESTDATA=true` or `TESTDATA_ONLY=true` (Section 13 summary is already in sections-meta.md and will be skipped via its own guard).

After reading all required files, execute their steps in order and generate the complete document in a single pass.
