# Section: sections.md
# Loaded on every invocation. Contains document Sections 1–10.
# mr-review has no conditional sections — all sections are always generated.

---

## Section 1: MR Summary

```
Title: <MR title>
Author: <author>
Branch: <source> → <target>
State: <open/merged/closed>
Description summary: [2-3 sentences summarising what this MR claims to do, in plain English]
```

---

## Section 2: Files Changed — Overview

A table of all changed files with a one-line description of what changed in each:

```
| File | Change Type | Summary of Change |
|---|---|---|
| path/to/File.java | Modified | Added priority field to VariableDTO; updated constructor |
| db/migration/V10__add_priority.sql | Added | New migration adding priority column to variable table |
| path/to/FileTest.java | Modified | Added test for priority field getter |
```

Change types: `Added`, `Modified`, `Deleted`, `Renamed`.

---

## Section 3: Code Quality Analysis

Analyse the diff for code quality issues. For each issue found:

```
| # | File | Line(s) | Severity | Issue | Suggestion |
|---|---|---|---|---|---|
```

Severity levels: `🔴 Critical` (must fix before merge), `🟡 Warning` (should fix), `🔵 Info` (suggestion/style).

Cover:
- **Code smells**: duplicated logic, overly complex methods, magic numbers/strings, inconsistent naming
- **Error handling**: missing null checks, unchecked exceptions, silent failure paths, swallowed errors
- **Security**: hardcoded credentials, SQL injection risk, unvalidated input, insecure deserialization, sensitive data in logs
- **Concurrency / thread safety**: shared mutable state, missing synchronisation, race condition patterns
- **Performance**: N+1 query patterns, unnecessary DB calls in loops, missing indexes referenced in code
- **Testability**: untestable code (private methods doing business logic with no test seam, static calls, hidden dependencies)
- **Backwards compatibility**: breaking API changes, removed fields, changed field types, method signature changes
- **Dead code**: commented-out code left in, unused imports, unused variables
- **Documentation**: public API methods with no Javadoc/docstring, complex logic with no inline comments

If no issues found in a category → state `None found`.

---

## Section 4: AC Coverage Analysis

Only generate if `--jira` given or ACs found in MR description.

```
| Acceptance Criterion | Addressed in Diff? | Evidence / Gap |
|---|---|---|
| [AC text] | ✅ Yes / ⚠️ Partial / ❌ No | [file/line reference or gap description] |
```

If `--jira` not given and no ACs found in MR description → write:
```
No Jira ticket or inline ACs provided. Re-run with --jira KEY to cross-reference ticket ACs against this diff.
```

---

## Section 5: Spec Compliance

Only generate if `--confluence` given.

```
| Spec Requirement | Addressed in Diff? | Evidence / Gap |
|---|---|---|
| [requirement] | ✅ Yes / ⚠️ Partial / ❌ No | [evidence or gap] |
```

If `--confluence` not given → write:
```
No Confluence spec provided. Re-run with --confluence URL to cross-reference spec requirements against this diff.
```

---

## Section 6: Clarification Questions

Questions targeted at the MR author. Minimum 5, target 8. Format:
```
[Short title]
Question: [specific question]?
Impact: [why this matters for testing or merge readiness]
```

Cover:
- Missing or incomplete test coverage visible in the diff
- Behaviour under failure conditions not addressed in the diff
- Backwards compatibility concerns
- Configuration or environment-specific behaviour
- Whether the change is behind a feature flag
- Concurrency or thread-safety assumptions
- Any TODO/FIXME comments left in the diff

---

## Section 7: Targeted Test Cases — What to Test for This Diff

Focus ONLY on what this MR changes — not the full feature.

**Gherkin format (default):**
```
| Scenario | Priority | Gherkin (Given/When/Then) | Test Data Required |
```

**Tab-separated format (`--no-gherkin`):**
```
Scenario	Priority	Steps / Expected Behavior	Test Data / Validation Points
```

Organized into **four named subsections** — do not skip any. Generate as many scenarios as the diff
warrants — cover every distinct behaviour, input, and failure mode. Counts below are floors only:

**7a. Happy Path** (floor: 3)
The expected successful flows for each changed behaviour. One scenario per distinct happy-path
behaviour — do not duplicate.

**7b. Negative Tests** (floor: 3)
Invalid inputs, missing required fields, wrong types, unauthorized access, forbidden state
transitions. Every new validation rule or error handler added gets its own negative test.
Mark scenarios relating to known defect areas with `(regression – known defect area)`.

**7c. Boundary / Edge Cases** (floor: 3)
Boundary values for numeric fields (min, max, min-1, max+1), empty collections, null/absent optional
fields, concurrent requests, exactly-at-SLA timing, maximum input lengths. Skip only if the diff
contains no boundaries, thresholds, or optional fields whatsoever — and state why.

**7d. Regression Tests** (floor: 2)
Existing behaviour that the diff touches but should NOT have changed. For each existing method or
endpoint modified in the diff, at least one scenario confirms pre-existing behaviour is preserved.

Apply BLACKBOX language rules to all four subsections when `--blackbox` is active.

---

## Section 8: Regression Risk

Which existing tests, flows, or integrations are most at risk from this change?

```
| Risk Area | Impact | Likelihood | Why At Risk | Recommended Test |
|---|---|---|---|---|
```

Minimum 4 rows. Use High/Medium/Low.

---

## Section 9: Missing Test Coverage

Based on the diff, what test cases are NOT present in the MR that should be?

```
| Missing Test | Severity | Why It Matters |
|---|---|---|
| [description of missing test] | 🔴 / 🟡 / 🔵 | [impact if not covered] |
```

Derive from:
- New public methods with no corresponding test file changes
- New error paths (catch blocks, validation) with no test for that path
- New SQL/queries with no integration test
- UI changes with no accessibility test

---

## Section 10: Merge Readiness Assessment

```
Overall: ✅ Ready to merge | ⚠️ Merge with caution | 🔴 Do not merge

Summary: [2-3 sentences]

Blockers (must fix before merge):
  - [item] (if any)

Recommended fixes (should fix, not blocking):
  - [item]

Suggestions (nice to have):
  - [item]

testing sign-off required: Yes / No
Reason: [why testing sign-off is or is not required]
```

Determine overall readiness:
- 🔴 if ANY `🔴 Critical` code quality issues found, or if ANY P0 ACs are unaddressed
- ⚠️ if `🟡 Warning` issues found, or if ACs partially addressed, or significant missing test coverage
- ✅ if no critical issues, ACs addressed (or no ACs provided), and test coverage is reasonable
