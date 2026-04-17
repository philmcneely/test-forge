## Step 4: Generate clarification questions and assumptions

Questions are targeted at the **spec author** — surface gaps before any ticket is written.

Cover:
- Scope boundaries — what is explicitly in/out of scope
- Missing acceptance criteria — sections that describe a feature but don't define done
- Ambiguous requirements — anything interpretable multiple ways
- Non-functional requirements — performance, security, accessibility, localisation gaps
- Dependencies — other systems, teams, or features this spec depends on
- Rollout strategy — feature flags, phased release, dark launch?
- Regulatory / compliance — any sign-off required before development starts?
- Analytics — what events/metrics should be tracked, how will success be measured?
- Ticket breakdown readiness — is the spec detailed enough to break into stories yet?
- Apply any P0 rules or known risk areas from the project config for targeted questions

Generate minimum 8–12 questions.

**Question format:**
```
[Short title]
Question: [specific question for spec author]?
Impact: [why this matters for spec completeness or ticket scoping]
```

**Assumption format** (one per question):
```
A[N] – [Short title]
[Assumption text written as if true. References Q[N].]
```

## Step 4b: Generate Section 3 — Suggested AC Skeleton

For each ambiguity or gap raised in Section 1, draft a BDD acceptance criterion in skeleton form.
These are intended for the spec author to add to the Confluence page or seed story ACs when the
spec is broken into Jira tickets.
Format each AC skeleton as:

```
AC[N] – [Short title] (addresses Q[N])
Given [precondition]
When [action]
Then [expected outcome]
And [additional assertion if needed]

⚠️ Draft — confirm with Q[N] before finalising.
```

Rules:
- Generate one AC skeleton per question where testable behaviour can be inferred.
- Where the question is non-functional (e.g. performance SLA, analytics event name), draft the AC
  as a measurable assertion: "Then the response time is under Xms" or "Then event Y is fired with
  property Z".
- Skip questions where the behaviour is truly unknown and cannot be inferred — do not fabricate
  business logic.
- Mark each skeleton as: ⚠️ Draft — confirm with Q[N] before finalising.
- Aim for 1 AC per question.
- These are drafts for the spec author to refine and add directly to the Confluence spec page or
  seed into story-level ACs when tickets are created.
