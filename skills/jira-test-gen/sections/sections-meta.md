# Section: sections-meta.md
# Loaded on every invocation.
# Contains document Sections 1, 2, 9, 11, and 12.
# Section 1 must be SKIPPED at generation time if NO_CLARIFY=true or NEG_ONLY=true.

---

## Section 1: Clarification Questions & Requirement Gaps

**Skip this section entirely if `NO_CLARIFY=true` or `NEG_ONLY=true`.**
When skipped, omit Section 1 from the document. Write Section 2 without Q-references.

When included, format each question as:
```
[Short title]
Question: [specific question]?
Impact: [why it matters for test design]
```

Minimum 8–12 questions. Cover: scope boundaries, AC ambiguities, NFRs, analytics, API contracts,
feature flags, regression scope, platform specifics, and regulatory sign-off.

---

## Section 2: Assumptions

**When `NO_CLARIFY=false` (standard mode):**
```
A[N] – [Short title]
[Assumption text. References Q[N].]
```

**When `NO_CLARIFY=true` (--no-clarify or --neg-only):**
```
A[N] – [Short title]
[Assumption text written as if true. No question reference.]
```

Generate at least 5 assumptions covering: test scope, environment availability,
test data access, third-party dependencies, and access permissions.

---

## Section 9: Accessibility Tests — minimum 8

Gherkin header:
```
| Scenario | WCAG Level | Gherkin (Given/When/Then) |
```

Tab-separated header (--no-gherkin):
```
Scenario	WCAG Level	Test Method
```

Cover: screen reader support (VoiceOver/TalkBack), keyboard/focus order, error announcements,
colour contrast ratios, Dynamic Type / font scaling, touch target sizes.

---

## Section 11: Risk Assessment — minimum 6

Gherkin header:
```
| Risk Area | Impact | Likelihood | Mitigation Strategy |
```

Tab-separated header (--no-gherkin):
```
Risk Area	Impact	Likelihood	Mitigation Strategy
```

Use High/Medium/Low for Impact and Likelihood. Include known regression risks from
`.test-gen.json` config where present.

---

## Section 12: Test Execution Priority

```
Smoke Tests
[bullet list — critical path verification, P0 items]

Progression Tests
[bullet list — primary happy path flows]

Regression Tests
[bullet list — areas at risk from this change]

Integration Tests
[bullet list — cross-service and cross-system scenarios]

Inflight Tests
[bullet list — scenarios for traffic already in flight during rollout]

Exploratory Tests
[bullet list — risk-driven unscripted exploration areas]
```

**If `NEG_ONLY=true`: omit the Progression Tests sub-section entirely.** Focus on:
Regression, Integration, Inflight, and Exploratory only.
