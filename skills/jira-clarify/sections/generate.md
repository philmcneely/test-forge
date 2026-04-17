## Step 4: Generate clarification questions and assumptions

Generate **Section 1: Clarification Questions & Requirement Gaps** and **Section 2: Assumptions** only. Do not generate any test cases.

**Section 1 format:**

```
[Short title]
Question: [specific question for PO/Dev/BA]?
Impact: [why this matters for test design or delivery]
```

Generate at least 8 questions, targeting 12. Cover:
- Scope boundaries — what is explicitly in/out of scope for this ticket
- AC ambiguities — acceptance criteria that are vague, missing, or contradictory
- Non-functional requirements — performance, security, accessibility, localisation
- Analytics and observability — what events/metrics should fire, how will success be measured
- API contracts — payload shapes, error codes, versioning, backwards compatibility
- Feature flags — is this behind a flag? what controls rollout?
- Regression scope — what existing flows could be affected?
- Platform specifics — any platform-specific behaviour differences?
- Regulatory / compliance — any sign-off required before release?
- Apply any P0 rules or known risk areas from the project config to generate targeted questions

**Section 2 format:**

One assumption per question, linked back by number:

```
A[N] – [Short title]
[Full assumption text, written as if it is true. References Q[N].]
```

## Step 4b: Generate Section 3 — Suggested AC Skeleton

For each ambiguity or gap raised in Section 1, draft a BDD acceptance criterion in skeleton form.
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
- These are drafts for the PO to paste directly into the Jira ticket and refine — write them
  concretely enough to be immediately useful.
