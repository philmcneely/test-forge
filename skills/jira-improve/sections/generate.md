## Step 4: Assess AC quality and rewrite as BDD

### AC Quality Scoring

For each AC in `ALL_ACS`, assign a quality score:

| Score | Label | Criteria |
|---|---|---|
| ✅ | Testable | Clear precondition, action, and measurable outcome. Could be automated as-is. |
| ⚠️ | Vague | Partially testable but missing specifics (e.g. "should work correctly", "loads fast", no error case defined). |
| ❌ | Missing/Untestable | Cannot be tested as written — no observable outcome, purely aspirational, or missing entirely. |

**Section 1 output format (AC Quality Assessment):**
```
AC[N] — [Original AC text, truncated to 120 chars if longer]
Score: ✅ Testable | ⚠️ Vague | ❌ Missing/Untestable
Reason: [one sentence explaining the score]
```

### BDD Rewrite Rules

For every AC scored ⚠️ or ❌, produce a rewritten BDD version. For ACs scored ✅, still rewrite
as Given/When/Then if the original is not already in that format — include them in the output
clearly labelled as already testable.

**BDD rewrite format:**
```
AC[N] — [Short descriptive title]
Original: [original AC text]
Score: ⚠️ Vague  (or ✅ / ❌)

Given [precondition — the starting state of the system or user]
When  [action — what the user or system does]
Then  [expected outcome — the observable, measurable result]
And   [additional assertion — if needed; omit if not]

[INFERRED — confirm with PO] ← append this tag to any Given/When/Then line that
                                was not stated in the original AC and was inferred
                                from the ticket description or parent epic context.
```

**Coverage requirements — include ACs for:**
- **Happy path**: the primary success scenario for each piece of functionality described
- **Boundary values**: any numeric limits, character limits, date ranges, or thresholds mentioned
- **Error states**: what happens when the action fails, input is invalid, or a dependency is down
- **Auth / permissions**: who can and cannot perform the action; what happens on unauthorised access
- **NFRs**: if performance, accessibility, or security is mentioned anywhere in the ticket, include
  at least one measurable AC for each (e.g. "Then the page loads within 2 seconds on a 4G connection")

**Do NOT invent business logic.** Infer only from:
- The ticket description
- `customfield_10063` / `customfield_10144` content
- Comments on the ticket
- Parent epic description and ACs

Mark anything inferred but not explicitly stated with `[INFERRED — confirm with PO]`.
Mark anything that is genuinely unknown and cannot be inferred with `[UNKNOWN — ask PO]` — do not
fabricate a plausible-sounding value.

### Section 3 — Inferred ACs (Gap Filling)

After rewriting existing ACs, identify gaps: scenarios that are clearly implied by the description
but have no corresponding AC. Generate new ACs for these gaps. Apply the same BDD format.

Mark every inferred AC with: `[INFERRED — confirm with PO]`

Common gaps to check for (apply only where relevant to this ticket):
- No AC for the unauthenticated / unauthorised user path
- No AC for the empty state (no data, first run, no results)
- No AC for the error/failure path
- No AC for the loading/pending state if async behaviour is described
- No AC covering what happens when the feature flag is off (if a flag is mentioned)
- No NFR AC despite performance or accessibility language in the description

### Section 4 — Suggested Description Update

If the ticket description is vague, uses undefined terms, or contradicts the ACs, produce a
cleaned-up version. Keep the same structure but:
- Replace undefined terms with specific ones (or mark `[UNKNOWN — ask PO]`)
- Remove redundant or aspirational language that adds no testable value
- Align the description with the rewritten ACs

If the description is already clear, write: `No changes suggested — description is clear and
consistent with the rewritten ACs.`
