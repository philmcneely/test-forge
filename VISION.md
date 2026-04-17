# Why we built Test Forge

## The challenge

Specs can always be improved.

Requirements get written under time pressure, refined across meetings and hallway conversations that don't always make it into writing — and by the time a ticket lands in a QA engineer's queue, not everyone involved has the same understanding of what was agreed. Acceptance criteria evolve. Edge cases emerge during development. And there's rarely enough time to sit in a room and work through every scenario before development starts.

The result: questions surface late, assumptions have to be made, and test documents sometimes reflect what was built rather than what was originally intended.

## The vision

**Test Forge is a thinking partner for the entire team -- not just QA.**

It applies testing thinking (boundary value analysis, risk-based testing, requirements scrutiny) to your Confluence specs and Jira tickets the moment they exist — surfacing ambiguities before a single line of code is written.

The workflow is intentionally iterative. Not a one-shot document generator. A conversation between the team and the spec, structured around rounds of questions, responses, and refinement:

1. **Spec appears** — a Confluence page or Jira ticket is created
2. **Questions surface** — targeted clarification questions highlight what's missing: scope boundaries, acceptance criteria gaps, API contracts, edge cases, regulatory flags
3. **The team responds** — PO/Dev/BA update the spec or ticket
4. **Questions refine** — re-run to surface anything that wasn't addressed, or new gaps that opened up during clarification
5. **Spec solidifies** — once clarified, generate tests that reflect what was actually agreed
6. **Gaps keep surfacing** — even after tests are generated, reviewing them often exposes new questions; iterate again

The goal isn't a perfect document on the first run. The goal is to keep asking the right questions until the spec is genuinely testable.

## Who uses it and why

### Product Owners

You write the spec. Test Forge shows you how a test engineer reads it.

Run `/confluence-clarify` on a page you're drafting and it will surface every assumption a tester would have to make, every acceptance criterion that's too vague to verify, every edge case you haven't considered. Before you've written a single story. Before you've handed anything to dev.

It's a fast, cheap pre-flight check for specs — and the questions it generates are exactly the ones you'd rather answer now than in a bug report six weeks from now.

### Developers

You need to understand what "done" looks like before you build it.

Run `/jira-clarify` on the ticket you're about to pick up. The questions it surfaces aren't QA being difficult — they're the real gaps in the requirements that will cause rework if left unaddressed. Better to know on Day 1 than on the day you open a PR.

You can also use `/confluence-breakdown` to split a large spec into properly-scoped Jira stories with acceptance criteria before the sprint planning meeting, so the conversation is about priorities rather than what the ticket even means.

### Testers and SDETs

You're the last line of defence before production — but you shouldn't be the first person to notice the spec is incomplete.

Test Forge helps you get ahead of that. As soon as a ticket arrives:

```
/jira-clarify PROJ-456          # surface the gaps
/jira-clarify PROJ-456 --create # post the questions while dev is still in the context
```

When the ticket is ready:

```
/jira-test-gen PROJ-456         # generate the full test document
/jira-test-gen PROJ-456 --create # post + create Zephyr TCs
```

The test document gives you boundary value analysis, negative cases, API contract tests, Gherkin scenarios — not boilerplate, but a structured starting point built from the actual requirements.

### Testing team leads and PMs

You want coverage, consistency, and visibility across a whole sprint — not just the tickets your most experienced tester happens to pick up.

The clarify skills make testing thinking available at the moment requirements are written, not after. The test-gen skills make it easier for junior testers to produce rigorous test documents without spending hours on structure.

Over time, the pattern of clarification questions also tells you something useful: where your process is weakest, what kinds of AC are routinely underspecified, which features carry the most risk.

## The full flow

```
Confluence spec
    └─▶ /confluence-clarify URL           ← surface requirement gaps early
            └─▶ Update spec in response
    └─▶ /confluence-breakdown URL         ← break spec into well-formed Jira stories
            └─▶ Stories created in Jira
                    └─▶ /jira-clarify KEY      ← refine individual ticket AC
                            └─▶ Dev updates ticket
                    └─▶ /jira-test-gen KEY     ← generate tests when ticket is ready
                            └─▶ Review tests — new gaps surface → /jira-clarify again
                    └─▶ /confluence-test-gen URL  ← or test from the spec directly
```

No single step is a one-way door. The flow is a loop. Questions lead to better specs. Better specs lead to better tests. Better tests lead to more questions — and that's good. That's the tool working as intended.

## What it is not

- Not a replacement for a QA engineer. It generates starting points, not final answers. Every document it produces needs human review.
- Not a one-click solution. Getting value from it means engaging with the questions it asks, not just posting them to Jira and moving on.
- Not a magic spec fixer. It finds gaps. Someone still has to close them.
- Not infallible. AI-generated output can be incomplete, wrong, or miss context that only a human would know. Treat everything it produces as a draft. You own the review.

> All output is AI-generated and provided as-is. You are responsible for verifying correctness before acting on any generated questions, test cases, assumptions, or ticket drafts. The authors of this tooling accept no liability for errors or omissions in generated output.

## How the skills are structured (router + section files)

Each skill's `SKILL.md` is a thin router — roughly 45–55 lines — that does nothing except declare flags and tell Claude which section files to read. The actual instructions live in `sections/` files that are loaded on demand.

**Why this matters: context is the bottleneck.**

Every token Claude loads at the start of a skill invocation costs real time and real money, and — more importantly — competes for space in the active context window with the actual work: the Jira ticket, the Confluence spec, the MR diff. A monolithic 600-line SKILL.md loads everything regardless of which flags you passed. The router pattern loads only what the current invocation needs.

Concretely:
- `/jira-test-gen PROJ-123 --neg-only` — skips loading `sections-happy.md` (~100 lines of happy-path test instructions that are irrelevant for a negative-only run)
- `/confluence-test-gen URL --no-testdata` — skips loading `testdata.md` (~120 lines of test data catalogue instructions)
- `/test-gen --file spec.md` — loads `sections/file.md` only; never touches `sections/prompt.md`
- `/test-gen` (no args) — loads `sections/prompt.md` only; never touches `sections/file.md`

For skills with no conditional sections (`confluence-breakdown`, `confluence-clarify`, `jira-clarify`, `mr-review`) the gain is smaller but still real: a ~45-line router instead of a ~260-line monolith means the model reaches the actual task instructions faster and with more context headroom for the content it fetches.

**The rule of thumb:** if a section of instructions is only relevant when a specific flag is active, it should be a separate file that is only loaded when that flag is active. The router decides what to load; the section files contain the instructions.

## Relationship to Atlassian Rovo

The [Atlassian Rovo MCP server](https://github.com/atlassian/atlassian-mcp-server) ships its own set of skills that cover adjacent territory. Understanding the boundary matters.

**Where Rovo's skills and ours overlap:**

| Task | Rovo skill | Our skill | Difference |
|---|---|---|---|
| Spec → Jira backlog | `spec-to-backlog` | `/confluence-breakdown` | Rovo creates Epic-first, ours is testing-focused with dry run, duplicate checking, and `--parent` flag |
| Bug triage + ticket | `triage-issue` | `/jira-clarify` (partial) | Rovo finds duplicates and creates/comments; ours focuses on AC gaps and requirement quality |

**Where only we cover the ground:**

- `/confluence-clarify` -- no Rovo equivalent. testing-lens requirement gap analysis.
- `/jira-test-gen` -- no Rovo equivalent. 12-section test document with Gherkin, boundary analysis, Zephyr TC creation.
- `/confluence-test-gen` -- no Rovo equivalent. Full test doc + Test Data Catalogue from a spec page.
- `/mr-review` -- no Rovo equivalent. Code review + testing analysis from an MR/PR diff.

**Where only Rovo covers the ground:**

- `generate-status-report` -- Jira data → Confluence status report for delivery managers and executives.
- `capture-tasks-from-meeting-notes` -- meeting notes (Confluence or pasted) → Jira tasks with assignees.
- `search-company-knowledge` -- semantic search across Confluence + Jira using Rovo's AI search layer.

The tools are **complementary, not competing**. Rovo covers the PM and project operations workflow. We cover the testing and spec quality workflow that Rovo doesn't touch.

**The integration direction we're headed:**

A `--rovo` flag (see ROADMAP.md) would let skills use the Rovo MCP as the reasoning engine for tasks where Rovo has a native skill -- offloading that work to Atlassian's infrastructure instead of consuming Claude tokens. For tasks only we handle (test generation, clarification questions, MR review), Claude continues to do the reasoning. The flag would also unlock Rovo's semantic search for richer context gathering across all skills.

---

## The assumption this tool makes

The most expensive place to discover a requirement gap is in production. The cheapest place is in the spec, before anything is built.

Every question surfaced by `/confluence-clarify` at spec time is an opportunity to close a gap before it becomes a bug. Every AC sharpened by `/jira-clarify` is a misunderstanding that has a chance to be resolved before it reaches a PR. Every negative test case generated by `/jira-test-gen` is an edge case that gets considered in QA rather than discovered in the field.

That's the bet. Small investment in requirements quality early. Better outcomes throughout delivery.
