# Section: format.md
# Loaded on every invocation. Contains Step 5 preamble, document header template,
# BLACKBOX language rules, and priority definitions.
# mr-review has no NEG_ONLY flag — all sections are always generated.

---

## Step 5: Analyze and generate the review document — in a single pass

Do NOT stop after gathering data. Immediately generate the full review document.

Apply any P0 rules and known regression risks from the project config throughout.

---

## Document header

```
MR-<MR_ID> — Code Review & Testing Analysis
MR URL: <MR_URL>
MR Title: <title>
Author: <author>
Source → Target: <source_branch> → <target_branch>
Generated: <date>
Mode: Standard | Black Box
Flags: [active flags]
Jira ticket: <JIRA_KEY> (fetched) | not provided
Confluence spec: <CONFLUENCE_URL> (fetched) | not provided
Files changed: <N>
Diff lines reviewed: <N> (truncated at 6000 | full)
```

**Mode determination:**
- `BLACKBOX=true` → `Black Box`
- Otherwise → `Standard`

Immediately after the document header block, before any section content, insert a testing callout box:

```
═══════════════════════════════════════════════════════
TEST CASES — Section 7
  7a. Happy Path      — N scenarios
  7b. Negative Tests  — N scenarios
  7c. Boundary/Edge   — N scenarios
  7d. Regression      — N scenarios
  Total: N scenarios across N subsections
═══════════════════════════════════════════════════════
```

Populate the counts after generating Section 7.

---

## If BLACKBOX=true — Black Box Language Rules

These rules apply to every test scenario in every section.

**The purpose of `--blackbox`:** every test scenario must describe how to exercise and verify
the behaviour exclusively through **public API endpoints or UI interactions** — the same channel
a real user or integration partner would use.

**Do NOT include in any scenario:**
- Internal class/type names (e.g. `CountDownLatch`, `ExecutorService`, `CompletableFuture`, `VariableRepository`)
- Internal queue, thread, or channel names (e.g. `criticalRequestQueue`, `threadPool`)
- Database table and column names (e.g. `RMPVariable table`, `PRIORITY column`, `SELECT priority FROM ...`)
- Source-level field names, getters/setters (e.g. `private String priority`, `getPriority()`)
- Internal exception class names — replace with the observable outcome visible to the caller
- Thread pool sizes, executor configuration, and other backend configuration values
- Any step that says "check the database" or "verify the table" or "query the DB"

**DO include — always express in observable terms:**
- Public API endpoint paths and HTTP methods (e.g. `POST /api/v2/variables`)
- API request fields and response fields as they appear in the API contract
- HTTP status codes (200, 400, 404, 500, 503, 429, etc.)
- SLA / timing values stated in the spec or ticket
- UI element labels, form field labels, validation messages, error text visible to the user
- Observable behavioural ordering expressed as API/UI outcome
- Observable isolation expressed as result (e.g. "concurrent requests return independent result sets")

**Rewrite pattern examples:**

| Internal (never use with --blackbox) | Black box (use this instead) |
|---|---|
| `Then the CountDownLatch reaches 0` | `Then all critical variable results appear in the response before any non-critical results` |
| `Then variables are placed in criticalRequestQueue` | `Then the API response includes all critical variable results` |
| `Then the variable is persisted in RMPVariable table with PRIORITY = '0'` | `Then GET /api/v2/variables/{id} returns "priority": 0` |
| `ExecutorService thread pool exhausted` | `Service returns 429 or 503; no requests are silently dropped` |
| `Then ClassCastException is thrown at runtime` | `Then the API returns 500 with a descriptive error message; no silent failure` |
| `SELECT COUNT(*) FROM variable WHERE priority = 0` | `GET /api/v2/variables?priority=0 returns the expected set of variables` |
| `Check the DB to confirm migration ran` | `GET /api/v2/variables/{id} returns the priority field in the response` |

---

## Priority definitions

- **P0** — must-not-ship-broken; blocks release
- **P1** — high; should be resolved before release
- **P2** — medium; fix in current or next sprint
- **P3** — low; nice-to-have, log and monitor
