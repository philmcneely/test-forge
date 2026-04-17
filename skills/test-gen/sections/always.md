## Step 0: Parse arguments and load config

**Parse ARGUMENTS:**
- Set `PROMPT_MODE=true` if no `--file` given, or if `--prompt` present
- Set `FILE_PATH` if `--file <path>` present (clears PROMPT_MODE)
- Set `GHERKIN=false` if `--no-gherkin` present, else `true` (Gherkin is the default)
- Set `NO_SYSTEM_CONTEXT=true` if `--no-system-context` present, else `false`

**Derive output filename:**
- Derive `OUTPUT_STEM` from filename (strip extension, replace spaces/special chars with underscores)
- Set `OUTPUT_FILE`:
  - `--no-gherkin`: `${OUTPUT_STEM}_tests_no_gherkin.md`
  - otherwise: `${OUTPUT_STEM}_tests.md`
  - pasted content: `pasted_content_tests.md` or `pasted_content_tests_no_gherkin.md`
  - prompt mode: no output file

**Load project config:**
Look for `.test-gen.json` in cwd. If found, read for domain context. Missing keys silently ignored.

**Resolve output directory:**
- If `--output-dir <path>` is present → use that path as `OUTPUT_DIR`.
- Else if `.test-gen.json` has an `"outputDir"` key → use that value as `OUTPUT_DIR`.
- Else → `OUTPUT_DIR=output` (a subdirectory of cwd).
- Create `OUTPUT_DIR` if it does not exist (e.g. `mkdir -p "$OUTPUT_DIR"`).
- Set `OUTPUT_FILE` to `<OUTPUT_DIR>/<OUTPUT_FILE>` (prepend the dir to the filename).

**Load system context:**
- If `NO_SYSTEM_CONTEXT=true` → set `SYSTEM_CONTEXT=none`, skip this step entirely.
- Otherwise resolve the path using this priority order:
  1. `--system-context <path>` flag value (if provided)
  2. `SYSTEM_CONTEXT_PATH` env var (set via `env` block in `.claude/settings.json` — workspace, or `~/.claude/settings.json` — user)
  3. `system-context.md` in cwd (legacy default)
- If a path was resolved, read that file using the Read tool and store its contents as `SYSTEM_CONTEXT`.
  This file describes the platform's integration map (entry points, call chain, downstream services,
  cross-system trigger rules). Include it as active context throughout generation — particularly
  when identifying integration risks in Sections 6, 7, 11, and 12.
- If the resolved file does not exist → warn "system-context file not found at <path>" and set `SYSTEM_CONTEXT=none`.
- If no path was resolved and no cwd file exists → set `SYSTEM_CONTEXT=none` and proceed without it.

## Error handling

- File not found: tell user and stop
- Unsupported format (Visio etc.): tell user how to convert and stop
- Extraction returns empty: tell user, suggest alternative format, stop
- Extraction returns fewer than 20 words from a binary file (PDF/docx/xlsx): treat as hard failure, tell user to convert to .txt/.md/.csv and stop
- Extraction returns very little text: warn but continue
- Very large file: warn but continue
- Python not found (for docx/xlsx extraction): tell user to install Python 3.9+ or convert file to .txt/.csv
- Never require pip installs — use stdlib only for all file parsing
