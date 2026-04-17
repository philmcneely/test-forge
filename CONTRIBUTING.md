# Contributing to Test Forge

Thanks for improving this skill set. Here's how the repo is structured and what to do for common changes.

---

## Repo structure

```
test-forge/
  skills/
    jira-clarify/
      SKILL.md               <- Thin router (~45 lines) -- parses flags, loads section files
      sections/
        always.md            <- Step 0: parse flags. Step 1: credentials
        fetch.md             <- Step 2: fetch ticket. Step 3: fetch parent/epic
        generate.md          <- Step 4: generate clarification questions
        write.md             <- Step 5: write output file. Step 6: dry run or --create
    jira-test-gen/
      SKILL.md               <- Thin router -- flags: --create, --no-gherkin, --blackbox, --follow, --no-clarify, --neg-only
      sections/
        always.md            <- Parse flags, load config, load system context
        fetch.md             <- Fetch ticket
        fetch-follow.md      <- Fetch linked pages (--follow only)
        sections-happy.md    <- Happy path test cases (skipped with --neg-only)
        sections-neg.md      <- Negative/boundary test cases
        sections-meta.md     <- Accessibility, exploratory, risk, priority sections
        format.md            <- Gherkin vs tab-separated format rules
        write.md             <- Write output file, post comment, create Zephyr TCs
    confluence-clarify/
      SKILL.md
      sections/
        always.md / fetch.md / generate.md / write.md
    confluence-breakdown/
      SKILL.md
      sections/
        always.md / fetch.md / analyze.md / write.md
    confluence-test-gen/
      SKILL.md
      sections/
        always.md / fetch.md / sections-happy.md / sections-neg.md / sections-meta.md
        format.md / testdata.md / write.md
    test-gen/
      SKILL.md               <- Thin router -- FILE_MODE (--file)
      sections/
        always.md / file.md
    mr-review/
      SKILL.md
      sections/
        always.md / fetch.md / sections.md / format.md / write.md
  settings.json.example   <- Claude Code settings template
  system-context.md       <- Platform integration map template
  README.md
  CONTRIBUTING.md
  VISION.md
  ROADMAP.md
  CHANGELOG.md
```

---

## How skills are structured

Each skill uses a **thin router + lazy-loaded section files** pattern. The `SKILL.md` is a short (~45-55 line) router that:
1. Declares frontmatter (name, description, allowed-tools)
2. Lists the section files to load for this invocation
3. Instructs Claude to Read each section file in order and follow it

The actual instructions live in `sections/` files. Only the sections relevant to the current flags are loaded -- this keeps context usage low (see `VISION.md` for the rationale).

---

## Common changes

### Adding a new document section

1. Edit the section list in `skills/jira-test-gen/SKILL.md`
2. Mirror the same addition to `skills/confluence-test-gen/SKILL.md`
3. If the section is test-case-bearing, add its standard and Gherkin table headers to both skills

### Changing the output format

The Gherkin pipe-table format (`GHERKIN=true`) is the default. The tab-separated multi-line format (`GHERKIN=false`) is activated with `--no-gherkin`.

### Adding a new flag

1. Add the flag to the `## Flag reference` table in the skill's `SKILL.md`
2. Add its parse line in Step 0 (argument parsing)
3. Add the output filename rule in the Output files table
4. Update `description:` in the frontmatter
5. Update the flag reference table in `README.md`

---

## Testing changes

All write-capable skills are dry run by default -- no `--create` flag means nothing is posted to Jira, Confluence, or Zephyr. Use any of the following to test:

```
/jira-clarify PROJ-123
/jira-test-gen PROJ-123
/confluence-clarify https://yourcompany.atlassian.net/wiki/spaces/DEV/pages/123/My+Spec
/confluence-test-gen https://yourcompany.atlassian.net/wiki/spaces/DEV/pages/123/My+Spec
/confluence-breakdown https://yourcompany.atlassian.net/wiki/spaces/DEV/pages/123/My+Spec
/mr-review https://github.com/org/repo/pull/1
```

---

## Submitting changes

1. Fork the repo (or branch from `main`)
2. Make your changes
3. Test with a dry run on a real ticket or page
4. Open a pull request with a short description of what changed and why
