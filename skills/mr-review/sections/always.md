# Section: always.md
# Loaded on every invocation. Contains Step 0 (argument parsing + config load),
# Step 1 (credentials), and error handling rules.

---

## Step 0: Parse arguments and load config

**Parse ARGUMENTS:**
- Extract `MR_URL` — the first positional argument
- Set `JIRA_KEY` if `--jira KEY` present, else empty
- Set `CONFLUENCE_URL` if `--confluence URL` present, else empty
- Set `CREATE=true` if `--create` present, else `false`
- Set `GHERKIN=false` if `--no-gherkin` present, else `true`
- Set `BLACKBOX=true` if `--blackbox` present, else `false`
- Detect platform: `GITLAB=true` if URL contains `merge_requests`; `GITHUB=true` if URL contains `/pull/`
- Extract `MR_ID` — the trailing numeric segment from the URL
- Derive `SLUG` — `mr-<MR_ID>`

**Derive OUTPUT_FILE:**
- Base: `mr-<MR_ID>_review`
- If `BLACKBOX=true` → append `_blackbox`
- If `GHERKIN=false` → append `_no_gherkin`
- Append `.md`

**Load project config:**
Look for `.test-gen.json` in cwd. Read: `projectContext`, `p0Rules`, `knownRegressionRisks`,
`regulatoryApprovals`. Missing keys silently ignored.

**Resolve output directory:**
- If `--output-dir <path>` is present → use that path as `OUTPUT_DIR`.
- Else if `.test-gen.json` has an `"outputDir"` key → use that value as `OUTPUT_DIR`.
- Else → `OUTPUT_DIR=output` (a subdirectory of cwd).
- Create `OUTPUT_DIR` if it does not exist (e.g. `mkdir -p "$OUTPUT_DIR"`).
- Set `OUTPUT_FILE` to `<OUTPUT_DIR>/<OUTPUT_FILE>` (prepend the dir to the filename).

---

## Error handling

- MR URL not recognized (not GitLab or GitHub format) → tell user expected format and stop
- API fetch fails (non-200) → print error, prompt user to paste the diff, wait
- No API token AND no pasted diff → tell user to set GITLAB_TOKEN / GITHUB_TOKEN or paste the diff, stop
- Diff truncated → note in document header, continue
- Jira ticket fetch fails → skip, note, continue
- Confluence fetch fails → skip, note, continue
- MR comment POST fails → log error, print review summary to terminal, continue
- Jira comment POST fails (--jira --create) → log error, continue
- Never print the API token value
- Re-runs are safe: each run generates a fresh review document and overwrites the output file.
  `--create` posts a new comment each run (no dedup guard — MR reviews are typically run once per MR).
