# Section: format.md
# Loaded on every invocation. Contains the document header template, mode
# determination, section skip rules, Gherkin format rules, tab-separated format
# rules, BLACKBOX language rules, and priority definitions.
# All rules in this file apply during Step 5 (generation).

---

## Step 5: Generate the test document — in a single pass

Do NOT stop after gathering data. Immediately generate the full document.

Apply any P0 rules, platform targets, and known regression risks from the project config throughout.

---

## Document header

Include at the top of every generated document:

```
<KEY> — Test Document
Source: <JIRA ticket URL>
Generated: <date>
Mode: Standard | Black Box | Neg/Boundary Only | Black Box + Neg/Boundary Only
Flags: [comma-separated list of active flags, e.g. --blackbox, --no-gherkin]
```

**Mode determination:**
- `BLACKBOX=true` and `NEG_ONLY=true` → `Black Box + Neg/Boundary Only`
- `BLACKBOX=true` only → `Black Box`
- `NEG_ONLY=true` only → `Neg/Boundary Only`
- Otherwise → `Standard`

---

## Section skip rules

- If `NO_CLARIFY=true` or `NEG_ONLY=true`: **skip Section 1**. Write Section 2 as general testing
  assumptions without `References Q[N]` back-references.
- If `NEG_ONLY=true`: **skip Sections 1, 3, 8, and 10**. Generate only Sections 2, 4, 5, 6, 7,
  9, 11, 12. In Section 12 (Test Execution Priority), omit the Progression Tests sub-section and
  focus on: Regression, Integration, Inflight, Exploratory.

Note: Sections 3, 8, and 10 are defined in `sections-happy.md` which is not loaded when
`NEG_ONLY=true` — their absence from the loaded context is the skip mechanism.
Section 1 is defined in `sections-meta.md` (always loaded) and must be skipped at generation time
based on `NO_CLARIFY` or `NEG_ONLY`.

---

## Default format — Gherkin (Given/When/Then)

Use markdown pipe tables for ALL sections.

Every test section uses a `Gherkin (Given/When/Then)` column:
```
| Scenario | Priority | Gherkin (Given/When/Then) | Test Data Required |
```

Gherkin steps separated by `<br>` inside table cells. Do NOT use code fences inside table cells.

Example cell content:
```
Given the user has an active account<br>When they submit a transfer of $500<br>Then the transfer is queued<br>And a confirmation screen is shown
```

Apply the same Gherkin structure to Edge Cases, Error Conditions, Negative Tests — every test section gets a Gherkin column.

---

## If GHERKIN=false (`--no-gherkin`) — Tab-separated format

**Header (tab-separated single line):**
```
Scenario	Priority	Steps / Expected Behavior	Test Data / Validation Points
```

**Each data row — one column per line, tab-indented, blank line between rows:**
```
[Scenario description]
	[Priority: P0/P1/P2/P3]
	[Steps or expected behavior — full text]
	[Test data or validation points — full text]

```

No pipe characters. No markdown. No compressed single-line rows.

---

## If BLACKBOX=true — Black Box Language Rules

These rules apply to every test scenario in every section: all Given/When/Then steps,
all table cells, and all exploratory/risk narrative.

**Do NOT include:**
- Internal class/type names (e.g. `CountDownLatch`, `ExecutorService`, `CompletableFuture`)
- Internal queue, thread, or channel names (e.g. `criticalRequestQueue`)
- Database table and column names (e.g. `RMPVariable table`, `PRIORITY column`)
- Source-level field names or pseudo-code (e.g. `private String priority`, `getPriority()`)
- Internal exception class names (e.g. `ClassCastException`, `NullPointerException`) — replace
  with the observable outcome visible to the caller
- Thread pool sizes, executor configuration, and other backend configuration values
- Any detail that requires DB access, source code access, or internal monitoring to verify

**DO include — always express in observable terms:**
- Public API request/response fields as they appear in the API contract (spec or OpenAPI)
- HTTP status codes (200, 400, 500, 503, 429, etc.)
- SLA / timing values stated in the spec or ticket
- UI element labels, validation messages, and error text visible to the user or API consumer
- Observable behavioral ordering expressed as outcome
- Observable isolation behavior expressed as result

**Rewrite pattern examples:**

| Internal (do not use) | Black box (use this instead) |
|---|---|
| `Then the CountDownLatch reaches 0` | `Then all critical variable processing completes before non-critical processing begins` |
| `Then variables are placed in criticalRequestQueue` | `Then critical variables are processed to completion first` |
| `Then the variable is persisted in RMPVariable table with PRIORITY = '0'` | `Then the Variable Definition API returns "priority": "0" for the created variable` |
| `ExecutorService thread pool exhausted` | `Under load the service returns 429 or 503; no requests are silently dropped` |
| `ClassCastException at runtime` | `Service returns 500 with a descriptive error message; no silent failure` |
| `nonCriticalRequestQueue has N items` | `N non-critical variable results are present in the response` |

---

## Priority definitions

- **P0** — must-not-ship-broken; blocks release
- **P1** — high; should be resolved before release
- **P2** — medium; fix in current or next sprint
- **P3** — low; nice-to-have, log and monitor
