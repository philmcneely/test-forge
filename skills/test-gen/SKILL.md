---
name: test-gen
description: Generate a comprehensive test document from pasted text, a local file, or print a copy/pasteable prompt for Rovo or any AI assistant. No Jira API required. Supports plain text, markdown, PDF, Word (.docx), Excel (.xlsx/.csv), and image files. Gherkin format by default — pass --no-gherkin for tab-separated format. Flags: --file <path>, --no-gherkin, --prompt (print Rovo prompt only), --no-system-context. Usage: /test-gen [--file <path>] [--no-gherkin] [--prompt] [--no-system-context]
allowed-tools: Bash, Read, Write
---

# Test Gen (No Jira Required)

You are a senior test engineer with expertise in test case design, boundary value analysis, risk-based testing, and accessibility testing. This skill generates a comprehensive test document from any input source — a local file, pasted text, or a ready-made prompt for Rovo or any AI assistant.

No Jira API, no Confluence API, no credentials required.

## How to invoke

```
/test-gen                              # print a Rovo-ready prompt to copy/paste
/test-gen --file spec.md               # read a local file and generate the test doc in Gherkin
/test-gen --file spec.pdf              # same — supports PDF, Word, Excel, CSV
/test-gen --file spec.md --no-gherkin  # tab-separated format instead of Gherkin
/test-gen --prompt                     # same as no args — print the Rovo prompt
```

After invoking with no `--file`, you can also paste spec content directly into the chat — the skill will detect it and generate the document.

## Flag reference

| Flag | Effect |
|---|---|
| *(none)* or `--prompt` | Print a copy/pasteable prompt for Rovo, ChatGPT, or any AI |
| `--file <path>` | Read a local file and generate the full test document in Gherkin format |
| `--no-gherkin` | Use tab-separated multi-line format instead of Gherkin |
| `--no-system-context` | Skip loading `system-context.md` even if it exists in cwd |

## Output files

| Mode | Output |
|---|---|
| `--prompt` | Printed to terminal only, no file |
| `--file spec.md` | `spec_tests.md` (stem of input filename) |
| `--file spec.md --no-gherkin` | `spec_tests_no_gherkin.md` |
| `--file path/to/My Feature.pdf` | `My_Feature_tests.md` |
| Pasted content | `pasted_content_tests.md` |

---

## Sections

Read the following section files in order. Each file contains the detailed instructions for that phase of execution.

**Always load:**

1. Read `sections/always.md` — parse flags, derive output filename, load config and system context

**Conditional — load based on mode:**

2. If `PROMPT_MODE=true` (no `--file` given, or `--prompt` present): Read `sections/prompt.md` — print the Rovo/AI prompt and stop
3. If `PROMPT_MODE=false` (`--file` given or content pasted): Read `sections/file.md` — extract content, validate, generate test document, write output file

Only one of `prompt.md` or `file.md` is loaded per invocation — they are mutually exclusive modes. The `--no-gherkin` flag affects content format within `file.md` but does not change which section file is loaded.
