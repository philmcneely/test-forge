## Step 5: Write the output file

Save to `<OUTPUT_DIR>/confluence-<SLUG>_tickets.md`:

```
confluence-<SLUG> — Draft Jira Ticket Breakdown
Source: <PAGE_TITLE>
URL: <CONFLUENCE_URL>
Generated: <date>
Mode: DRY RUN | LIVE (--create)
Parent epic: <PARENT_KEY if set, else "New epic in breakdown" or "None">

=== TICKET BREAKDOWN ===

[all drafted tickets]

=== CREATION SUMMARY ===
[populated in Step 6 if --create, otherwise:]
Dry run complete. Review the tickets above, then re-run with --create to create them in Jira.

Suggested flow after creation:
  1. /jira-clarify <KEY>  on each story for testing-focused clarification
  2. /jira-test-gen <KEY>  when ready to generate the full test document
```

Confirm file path to user — print the full absolute path: `<cwd>/<OUTPUT_DIR>/confluence-<SLUG>_tickets.md`.

## Step 6: Create tickets in Jira (--create only)

**Skip entirely if CREATE=false** (already handled in Step 5 message above).

**Resolve PROJECT_KEY:**
1. From `--parent` key → `${PARENT_KEY%%-*}`
2. From `.test-gen.json` `defaultProjectKey`
3. Neither present and running interactively → ask user: *"Which Jira project key should tickets be created in? (e.g. PROJ)"* — wait for answer before proceeding
4. Neither present and running headlessly (no terminal / CI context) → print error: *"PROJECT_KEY could not be resolved. Set `defaultProjectKey` in `.test-gen.json` or pass `--parent <EPIC-KEY>`."* and stop.

**Resolve available issue types (MCP only):**

Before creating any tickets, fetch the project's available issue types so we use names that actually exist:

```
mcp__mcp-atlassian__jira_get_project_issues_metadata(
  project_key = PROJECT_KEY
)
```

From the response, build a type map — find the actual names (case-sensitive as returned) for:
- `EPIC_TYPE` — first type whose name matches (case-insensitive): "Epic", "Initiative", "Theme"
- `STORY_TYPE` — first type whose name matches: "Story", "User Story"
- `TASK_TYPE` — first type whose name matches: "Task", "Engineering Task"
- `BUG_TYPE` — first type whose name matches: "Bug", "Defect"
- `FALLBACK_TYPE` — first non-Epic, non-Subtask, non-Sub-task type in the list

**Type selection logic per ticket (apply after building the map above):**
- Drafted type is "Epic" → use `EPIC_TYPE` (if not found, log warning and use `FALLBACK_TYPE`)
- Drafted type is "Bug" → use `BUG_TYPE` if available, else `TASK_TYPE`, else `FALLBACK_TYPE`
- Drafted type is "Story" → use `STORY_TYPE` if available, else `TASK_TYPE`, else `FALLBACK_TYPE`
- Drafted type is "Task" → use `TASK_TYPE` if available, else `FALLBACK_TYPE`

**If MCP metadata call fails or is unavailable (curl fallback path):**
- Use these safe defaults: Epic → `"Epic"`, Story → `"Story"`, Task → `"Task"`, Bug → `"Bug"`
- On creation failure with error containing "issue type" or "issuetype" → retry once with `"Task"` as fallback
- Log: `⚠️ Issue type "<type>" not confirmed for project PROJECT_KEY — used default. If creation fails, set issue types manually.`

Log the resolved type map before creating: `ℹ️ Issue types for PROJECT_KEY: Epic="X", Story="Y", Task="Z", Bug="W"`

**Idempotency guard — check for existing tickets before creating:**

For each drafted ticket, search Jira for an existing issue with the same summary in the project. The `~` (contains) operator is used because JQL does not support exact-equality on `summary`. To reduce false positives, compare returned summaries in code after the search returns rather than relying solely on the JQL result.

Before constructing the JQL query string, sanitise the summary:
1. Escape `"` → `\"` and `\` → `\\`
2. Remove or replace any remaining JQL special characters that can appear outside quotes (`(`, `)`, `:`, `+`, `-`, `[`, `]`, `{`, `}`, `^`, `~`, `*`, `?`, `!`, `&`, `|`) with a single space, then collapse multiple spaces
3. Use the sanitised value inside a quoted `~` expression

**MCP:**
```
mcp__mcp-atlassian__jira_search(
  jql = "project = PROJECT_KEY AND summary ~ \"SANITISED_SUMMARY\" ORDER BY created DESC",
  fields = "summary,status,issuetype",
  limit = 5
)
```

Compare the returned summaries against the drafted summary: case-insensitive, whitespace-normalised (collapse runs of whitespace, trim leading/trailing). Only skip if a returned summary is an exact normalised match — a fuzzy partial match alone is not sufficient to skip, to avoid false positives. Mark skipped tickets as `⏭️ SKIPPED (already exists: KEY — summary)`. Continue with remaining tickets.

**Create non-skipped tickets in order — epic first, then stories:**

**MCP:**
```
mcp__mcp-atlassian__jira_create_issue(
  project_key = PROJECT_KEY,
  summary = "<summary>",
  issue_type = <resolved type from map above — EPIC_TYPE | STORY_TYPE | TASK_TYPE | BUG_TYPE>,
  description = "<description + ACs in markdown>",
  additional_fields = "{\"labels\": [...], \"priority\": {\"name\": \"...\"}, \"parent\": \"EPIC-KEY\"}"
)
```

On failure with error containing "issue type" or "issuetype": retry once using `FALLBACK_TYPE`. Log the retry.

For stories under a new epic: use the key returned from the epic creation as parent.
For stories under `--parent`: use `PARENT_KEY` as parent.

If creation fails for any other reason → log error, continue with remaining tickets.

**Update `confluence-<SLUG>_tickets.md`** — replace CREATION SUMMARY:
```
=== CREATION SUMMARY ===
Processed N tickets (M created, K skipped, F failed):
  ✅ PROJ-101  Epic: <summary>
  ✅ PROJ-102  Story: <summary> (child of PROJ-101)
  ⏭️ SKIPPED   Story: <summary> — already exists as PROJ-099
  ❌ FAILED    Story: <summary> — <error>

Next steps:
  - /jira-clarify <KEY>  on each story for testing clarification questions
  - /jira-test-gen <KEY>  when ready to generate the full test document
```
