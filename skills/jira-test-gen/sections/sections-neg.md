# Section: sections-neg.md
# Loaded on every invocation.
# Contains document Sections 4, 5, 6, and 7.

---

## Pre-generation: AC Inversion

Before generating Sections 4–7, list all ACs from the ticket (from description,
customfield_10063, customfield_10144, and parent epic). For each AC:

1. State the AC in one line
2. Invert it: "What would have to be true for this AC to FAIL?"
3. Derive at least 1 negative scenario from that inversion

These AC-derived negatives take priority — place them first within each section.
Generic category scenarios (null inputs, timeouts, etc.) supplement but do not replace them.

Mark AC-derived negatives with: `(AC inversion: AC[N])`

---

## Section 4: Edge Cases

Gherkin header:
```
| Scenario | Priority | Gherkin (Given/When/Then) | Validation Points |
```

Tab-separated header (--no-gherkin):
```
Scenario	Priority	Expected Behavior	Validation Points
```

**Coverage completeness checklist — generate a scenario for each that applies to this ticket.
Skip items that are genuinely not relevant; do not pad with invented scenarios.**

- [ ] Every AC inversion that surfaces an edge condition (place first)
- [ ] Null or empty input for each user-supplied field
- [ ] Maximum and minimum boundary values for any numeric, length, or date constraint mentioned
- [ ] Zero-value inputs where zero has distinct behaviour (e.g. zero quantity, zero price)
- [ ] Non-existent or deleted resource (e.g. ID that no longer exists)
- [ ] Unicode, emoji, and non-ASCII characters in text fields
- [ ] Float precision edge cases if currency or measurement is involved
- [ ] Unusual but valid input combinations that cross field boundaries (e.g. max chars in every field simultaneously)
- [ ] State machine edges: what happens at each transition boundary (e.g. last item in stock, session about to expire)

---

## Section 5: Data Variation Testing

Gherkin header:
```
| Scenario | Priority | Test Data Combinations | Gherkin (Given/When/Then) |
```

Tab-separated header (--no-gherkin):
```
Scenario	Priority	Test Data Combinations	Validation Points
```

**Coverage completeness checklist:**

- [ ] One equivalence class per distinct valid input partition (not one test per value)
- [ ] Boundary values for each partition (lower bound, upper bound, just outside each)
- [ ] Pairwise / combinatorial coverage for any feature with 2+ independent input variables
- [ ] Volume / load data set if the feature handles lists, files, or batch inputs
- [ ] Locale or format variants if the ticket mentions internationalisation, currency, or dates

---

## Section 6: Error Conditions

Gherkin header:
```
| Scenario | Priority | Gherkin (Given/When/Then) | Validation Points |
```

Tab-separated header (--no-gherkin):
```
Scenario	Priority	Expected Behavior	Validation Points
```

**Coverage completeness checklist:**

- [ ] Every AC inversion that surfaces an error/failure condition (place first)
- [ ] Each downstream service or API dependency the ticket touches: unavailable (5xx / timeout)
- [ ] Each downstream dependency: returns a client error (4xx) for a valid request
- [ ] Partial failure: one dependency succeeds, another fails mid-flow
- [ ] Cascading failure: how the system behaves when retries exhaust
- [ ] Invalid or malformed input that bypasses client-side validation (server-side enforcement)
- [ ] Concurrent conflicting writes (if the ticket creates or mutates shared state)
- [ ] Apply P0 rules from `.test-gen.json` config where relevant

---

## Section 7: Negative / Compatibility Test Cases

Gherkin header:
```
| Scenario | Priority | Gherkin (Given/When/Then) | Validation Points |
```

Tab-separated header (--no-gherkin):
```
Scenario	Priority	Expected Behavior	Validation Points
```

**Coverage completeness checklist:**

- [ ] Every AC inversion that surfaces a permission or compatibility violation (place first)
- [ ] Auth boundary: one scenario per role or user type that should NOT have access — verify 401/403
- [ ] Anti-condition: for each AC that grants access or state to user A, verify user B is denied
  (auth/permissions boundary) — mark `(anti-condition: AC[N])`
- [ ] Anti-condition under load: for each AC satisfied under normal conditions, verify it holds
  under concurrency or high load — mark `(anti-condition: load/concurrency)`
- [ ] Idempotency: repeated submission of the same action produces the same result, not duplicates
- [ ] Deprecated input formats, old API versions, or legacy schema fields are rejected or handled
- [ ] Missing required fields are rejected with a specific, actionable error (not a 500)
- [ ] Schema mismatch: unexpected field types or extra fields in request payloads
- [ ] Known regression areas from `.test-gen.json` or ticket history — mark `(regression – known defect area)`
