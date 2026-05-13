# Enhancement: Modular QA Platform

## Vision

A modular, pluggable QA platform covering the entire testing lifecycle. Each capability is an independent module that can be used standalone or composed into end-to-end workflows. No module assumes a specific project management tool, test case manager, or CI provider.

Teams pick the modules they need:

```
┌──────────────────────────────────────────────────────────────────┐
│                        QA Platform Modules                       │
│                                                                  │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐ │
│  │ Requirements │ │ Test Design │ │ Test Case   │ │ Code Gen  │ │
│  │ Analysis     │ │             │ │ Management  │ │           │ │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └─────┬─────┘ │
│         │               │               │              │        │
│  ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐ ┌────▼──────┐ │
│  │ Execution   │ │ Self-Healing│ │ Defect Mgmt │ │ Observ.   │ │
│  │             │ │             │ │             │ │ & Analytics│ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └───────────┘ │
│                                                                  │
│  ┌─────────────┐ ┌─────────────┐                                │
│  │ Visual      │ │ API Testing │                                │
│  │ Regression  │ │ & Mocking   │                                │
│  └─────────────┘ └─────────────┘                                │
└──────────────────────────────────────────────────────────────────┘
```

Each module has its own integration adapters. Jira is one adapter. Azure DevOps, Linear, GitHub Issues, TestRail, or plain files are others.

---

## Modules

### 1. Requirements Analysis

**What it does:** Evaluates acceptance criteria for testability. Identifies gaps, ambiguities, and missing edge cases. Suggests rewrites in structured BDD format. Comments on the source ticket/document with feedback.

**The AC quality gate:**

| AC Quality | Action |
|---|---|
| Structured + specific + edge cases | Proceed to test design |
| Structured but missing edge cases | Comment with suggestions, proceed with caveats |
| Vague or freeform | Comment with BDD rewrite suggestion, flag for author |
| No AC at all | Comment: "No acceptance criteria found" |

**Example output (posted to ticket):**

```
Automated AC Review

3 acceptance criteria found. Issues detected:

Missing specificity:
- "User can reset their password" — What's the entry point?
- "Email is sent" — Within what timeframe?

Missing error cases:
- What happens with an unregistered email? (user enumeration risk)
- Rate limiting on reset requests?

Suggested rewrite (Given/When/Then):

  Given a registered user on the login page
  When they click "Forgot Password" and submit their email
  Then they receive a reset email within 60 seconds
  And the reset link expires after 24 hours

  Given an unregistered email address
  When submitted to the password reset form
  Then the same success message is displayed (no user enumeration)

Verdict: Not ready for test generation. 3 gaps need resolution.
```

**Integration adapters:**

| Source | Adapter | Status |
|---|---|---|
| Jira | MCP or REST API | test-forge `/jira-clarify` — built |
| Confluence | MCP or REST API | test-forge `/confluence-clarify` — built |
| Local files | File reader | test-forge `/test-gen --file` — built |
| Azure DevOps | REST API | Not built |
| Linear | GraphQL API | Not built |
| GitHub Issues | REST API | Not built |

**Where it lives:** `test-forge`

---

### 2. Test Design

**What it does:** Generates structured test documents from requirements. Covers the full testing spectrum with a standardized 12-section format:

1. Clarification Questions & Requirement Gaps
2. Assumptions
3. Happy Path Scenarios (min 10)
4. Edge Cases (min 10) — driven by AC inversion
5. Data Variation Testing (min 7)
6. Error Conditions (min 10)
7. Negative / Compatibility Tests (min 10)
8. Cross-Platform / Compatibility Testing
9. Accessibility Tests (min 8) — WCAG 2.1 AA
10. Exploratory Test Charter
11. Risk Assessment (min 6)
12. Test Execution Priority (P0-P3)

**Input:** Requirements from any source (Jira ticket, Confluence page, local file, pasted text).

**Output:** Markdown test document. Optionally a Test Data Catalogue.

**Testing methodology baked in:**
- Boundary Value Analysis
- Risk-Based Testing (RISE framework)
- AC Inversion (for every AC, derive: "what makes this fail?")
- Coverage completeness checklists per section

**Integration adapters:**

| Source | Adapter | Status |
|---|---|---|
| Jira ticket | MCP or REST | test-forge `/jira-test-gen` — built |
| Confluence page | MCP or REST | test-forge `/confluence-test-gen` — built |
| Local file (PDF, Word, Excel, Markdown, image) | File reader | test-forge `/test-gen --file` — built |
| MR/PR diff | GitLab/GitHub API | test-forge `/mr-review` — built |

**Where it lives:** `test-forge`

---

### 3. Test Case Management

**What it does:** Creates and manages test cases in a test case management (TCM) tool. Maps generated test scenarios to TCM entities. Handles deduplication, priority mapping, and cycle/folder organization.

**Integration adapters:**

| TCM Tool | Adapter | Status |
|---|---|---|
| Zephyr Scale (Cloud) | REST API v2 | test-forge — built (untested) |
| Zephyr Scale (Server) | REST API v1 | Not built |
| TestRail | REST API | Not built |
| Xray (Jira plugin) | REST API | Not built |
| qTest | REST API | Not built |
| Local files (markdown) | File writer | test-forge — built (default output) |

**Zephyr Scale API endpoints used:**

| Endpoint | Purpose |
|---|---|
| `POST /testcases` | Create test case |
| `GET /testcases` | Duplicate detection |
| `POST /testcycles` | Create test cycle |
| `POST /testexecutions` | Create test execution |
| `PUT /testexecutions/{id}` | Update execution status |

**What needs building:**
- Result reporting back to TCM (execution status after test runs)
- Test cycle creation per CI run
- `DRY_RUN` modes for all TCM adapters
- TestRail and Xray adapters (common enterprise alternatives to Zephyr)

**Where it lives:** `test-forge` (creation side), `playwright-ai-framework*` (reporting side)

---

### 4. Test Code Generation

**What it does:** Generates executable test code from requirements or test documents. Validates generated code structurally before saving. Supports multiple test frameworks and languages.

**Generation modes:**

| Mode | How | Tradeoff |
|---|---|---|
| Template | Predefined code templates + knowledge base selectors | Fast, deterministic, no API cost |
| LLM | OpenAI, Claude, Ollama, Azure | Intelligent, handles ambiguity, costs tokens |
| Hybrid | LLM first, template fallback | Best of both |

**Knowledge base:** JSON schema of page objects (selectors), test flows (step sequences), and test data. Updated automatically by indexing existing GitHub repos.

**Supported frameworks:**

| Framework | Language | Status |
|---|---|---|
| Playwright + pytest | Python | Built |
| Playwright + @playwright/test | TypeScript | Planned |
| Cypress | JavaScript | Planned |
| Selenium | Java/Python | Planned |

**What needs building:**
- Accept test-forge test document as generation context (richer than raw AC)
- Annotate generated tests with TCM keys (e.g., `ZEPH-T801` in test name)
- TypeScript generation mode
- Report generation status back to source ticket

**Where it lives:** `automated-test-generation-framework`

---

### 5. Test Execution

**What it does:** Runs tests with retries, parallel execution, multi-browser support, and cloud execution. Records structured metrics for every test run.

**Capabilities:**

| Capability | Python Framework | TS Framework |
|---|---|---|
| Multi-browser (Chromium, Firefox, WebKit) | Built | Built |
| Retry with configurable count/delay | Built | Built |
| Parallel execution | Built (pytest-xdist) | Built (Playwright workers) |
| Headed/headless toggle | Built | Built |
| Screenshot on failure | Built | Built |
| Video recording | Built | Built |
| Allure reporting | Built | Built |
| Cloud execution (BrowserStack) | Built | Built |

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`

---

### 6. AI Self-Healing

**What it does:** When a test fails after all retries, queries a local or remote LLM to analyze the failure. Produces structured healing reports with root cause analysis, confidence scores, and suggested fixes. Optionally generates a corrected test file.

**LLM providers:**

| Provider | Status |
|---|---|
| Ollama (local) | Built — both frameworks |
| Claude API | Planned |
| OpenAI API | Planned |

**What needs building:**
- Configurable model selection (currently hardcoded to `llama3.1:8b`)
- Confidence threshold enforcement
- Heal-and-alert pattern: successful healing creates a TODO for human review
- Feed healing results into observability metrics

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`

---

### 7. Defect Management

**What it does:** Automatically creates bug tickets when tests fail on main branch. Deduplicates by test ID + error category to avoid flooding. Auto-resolves bugs when tests pass again.

**Rules:**
- Only create bugs on `main` branch (not PRs)
- Only after all retries exhausted
- Deduplicate: same test + same error category = update existing bug
- Auto-resolve: test passes on main → transition bug to Resolved
- Include: error message, screenshot, AI healing analysis, CI run link

**Integration adapters:**

| Tool | Adapter | Status |
|---|---|---|
| Jira | REST API | Basic comment posting — built. Auto-bug creation — not built |
| Azure DevOps | REST API | Not built |
| Linear | GraphQL API | Not built |
| GitHub Issues | REST API | Not built |

**Environment variables (when built):**

| Variable | Default | Description |
|---|---|---|
| `AUTO_BUG_ENABLED` | `false` | Enable automatic bug creation |
| `AUTO_BUG_PROVIDER` | — | `jira`, `github`, `linear`, `azdo` |
| `AUTO_BUG_PROJECT` | — | Project key for bug creation |
| `AUTO_BUG_LABELS` | `auto-bug,test-failure` | Labels applied to created bugs |
| `AUTO_BUG_RESOLVE` | `false` | Auto-resolve on test pass |
| `AUTO_BUG_BRANCH` | `main` | Only create bugs for failures on this branch |

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`

---

### 8. Observability & Analytics

**What it does:** Records structured per-test metrics. Tracks flake rate, pass rate, MTTD, execution cost, slowest tests, and error categorization. Outputs JSONL for analysis and generates summary reports.

**Metrics tracked per test:**

| Field | Description |
|---|---|
| test_id | Unique test identifier |
| test_name | Human-readable test name |
| suite | Test suite/module |
| status | passed, failed, skipped, timedOut |
| duration_ms | Execution time |
| retry_count | Number of retries |
| browser | Browser engine |
| commit_sha | Git commit (auto-detected) |
| branch | Git branch (auto-detected) |
| heal_event | Whether AI healing triggered |
| error_category | timeout, element-not-found, navigation, assertion, browser-crash, other |

**Outputs:**

| Output | Format | Status |
|---|---|---|
| Per-test metrics | JSONL | Built — both frameworks |
| Summary | JSON | Built — both frameworks |
| Markdown report | Markdown | Built — both frameworks |
| CI artifact upload | GitHub Actions | Built — both frameworks |
| Grafana dashboard | SQLite → Grafana | Planned |
| Trend analysis | Time-series over multiple runs | Planned |

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`

---

### 9. Visual Regression

**What it does:** Pixel-level screenshot comparison against baselines. First run saves baseline; subsequent runs compare and fail if diff exceeds tolerance. Generates diff images highlighting changes.

| Aspect | Python Framework | TS Framework |
|---|---|---|
| Library | OpenCV + NumPy | pixelmatch + pngjs |
| Native deps | Yes (opencv-python) | No (pure JS) |
| Element-level | Yes | Yes |
| Full-page | Yes | Yes |
| Tolerance config | Yes | Yes |
| Diff images | Yes | Yes |

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`

---

### 10. API Testing & Mocking

**What it does:** Intercepts and mocks HTTP requests during test execution. Pre-built response templates for common scenarios (401, 404, 500, etc.). Supports request/response logging for inspection.

**Capabilities:**
- Mock GET/POST/PUT/DELETE by URL pattern
- Load mock data from files
- Simulate network failures and slow responses
- Response templates (success, unauthorized, notFound, serverError, etc.)
- Request/response logging

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`

---

## How the Repos Map to Modules

| Module | test-forge | automated-test-gen | playwright-ai (Py) | playwright-ai (TS) |
|---|---|---|---|---|
| Requirements Analysis | Primary | — | — | — |
| Test Design | Primary | — | — | — |
| Test Case Management | Creation | — | Result reporting | Result reporting |
| Code Generation | — | Primary | — | — |
| Execution | — | — | Primary | Primary |
| Self-Healing | — | — | Primary | Primary |
| Defect Management | — | — | Primary | Primary |
| Observability | — | — | Primary | Primary |
| Visual Regression | — | — | Primary | Primary |
| API Testing | — | — | Primary | Primary |

---

## Example Composition: Jira + Zephyr Workflow

This is one way to compose the modules. Other compositions are equally valid (e.g., GitHub Issues + TestRail, or no project management tool at all).

```
Story with AC (Jira)
    │
    ▼
[Module 1: Requirements Analysis]
    │ via test-forge /jira-clarify
    │ Posts feedback to ticket if AC needs work
    ▼
[Module 2: Test Design]
    │ via test-forge /jira-test-gen
    │ 12-section test document generated
    ▼
[Module 3: Test Case Management]
    │ via test-forge /jira-test-gen --create
    │ Zephyr Scale test cases created, linked to story
    ▼
[Module 4: Code Generation]
    │ via automated-test-generation-framework
    │ Playwright test code generated from AC + test doc
    │ Tests annotated with ZEPH-* keys
    ▼
[Module 5: Execution]  +  [Module 6: Self-Healing]
    │ via playwright-ai-framework(-ts)
    │ CI runs tests, healing fires on failure
    ▼
[Module 7: Defect Management]
    │ Auto-create bugs in Jira on main-branch failures
    │ Auto-resolve when tests pass again
    ▼
[Module 8: Observability]
    │ Metrics recorded, summary generated
    ▼
[Module 3: Test Case Management — result reporting]
    │ Zephyr test cycle updated with pass/fail per test case
    │ Story gets summary comment
    ▼
Done — dashboards show coverage, flake rate, bug burn-down
```

### Example Composition: No Project Management Tool

```
Local spec file (PDF, Markdown, Word)
    │
    ▼
[Module 1: Requirements Analysis]
    │ via test-forge /test-gen --file spec.md
    │ Prints feedback to console
    ▼
[Module 2: Test Design]
    │ Same invocation — 12-section test doc written to disk
    ▼
[Module 4: Code Generation]
    │ via automated-test-generation-framework (template mode)
    │ No API calls needed
    ▼
[Module 5: Execution]  +  [Module 6: Self-Healing]
    │ pytest / npx playwright test
    ▼
[Module 8: Observability]
    │ metrics.jsonl + report.md
    ▼
Done — no Jira, no Zephyr, no cloud services
```

---

## Zephyr Scale Testing Strategy

### Problem: No Zephyr Scale license

### Solution options (cheapest first):

1. **Atlassian developer instance (free)** — `developer.atlassian.com` provides a free Jira Cloud instance. Add Zephyr Scale from the Marketplace (30-day free trial). Full test environment at $0.

2. **Mock-based development** — Build against the documented Zephyr Scale API v2 spec. Unit tests mock all HTTP calls. `ZEPHYR_DRY_RUN=true` for integration paths. Validate with trial when ready.

3. **Zephyr Scale Cloud sandbox** — SmartBear may provide sandbox/demo instances for integration development. Worth checking.

### Development approach

| Phase | How |
|---|---|
| Build | Mock-based unit tests. `DRY_RUN=true` for all integration code. |
| Validate | 30-day Zephyr trial on free Atlassian dev instance. Run all paths end-to-end. |
| Ongoing | `DRY_RUN=true` in CI. Real calls only in manual/staging workflows. |

### Reference implementation

test-forge already has Zephyr Scale API integration in `skills/jira-test-gen/sections/write.md`:
- Test case creation with priority mapping
- Idempotency guard (duplicate detection by name)
- Rate limiting (0.3s between calls, exponential backoff on 429)
- Graceful skip if token not set

This code serves as the reference for building execution reporting in both Playwright frameworks.

---

## What Needs Building (by module)

### Requirements Analysis (test-forge)

| Item | Effort | Description |
|---|---|---|
| Validate `--create` paths | Medium | Test all 6 skills against real Jira/Confluence |
| AC scoring rubric | Medium | Structured scoring (not just ad-hoc LLM eval) |
| Azure DevOps adapter | Medium | Read work items, post comments |
| GitHub Issues adapter | Small | Read issues, post comments |
| Linear adapter | Small | GraphQL API, read/write |

### Test Case Management

| Item | Effort | Where |
|---|---|---|
| Zephyr execution reporting | Medium | playwright-ai-framework, playwright-ai-framework-ts |
| Zephyr test cycle creation | Medium | playwright-ai-framework, playwright-ai-framework-ts |
| `ZEPHYR_DRY_RUN` mode | Small | All repos |
| TestRail adapter | Medium | New integration |
| Xray adapter | Medium | New integration |

### Code Generation (automated-test-generation-framework)

| Item | Effort | Description |
|---|---|---|
| Test document input | Medium | Accept test-forge markdown as context |
| TCM key annotation | Small | Embed ZEPH-*/TR-* keys in generated test names |
| TypeScript output | Large | Generate @playwright/test code (currently Python only) |
| Generation status reporting | Small | Post status back to source ticket |

### Defect Management (both Playwright frameworks)

| Item | Effort | Description |
|---|---|---|
| Bug auto-creation | Medium | Create deduped bug tickets on main-branch failures |
| Bug auto-resolution | Small | Transition bugs on test pass |
| Provider abstraction | Medium | Interface for Jira, GitHub, Linear, Azure DevOps |

### Self-Healing (both Playwright frameworks)

| Item | Effort | Description |
|---|---|---|
| Configurable model | Small | Env var for model selection |
| Claude/OpenAI API support | Medium | Remote LLM option alongside local Ollama |
| Heal-and-alert | Small | Log healed locators for human review |
| Confidence threshold | Small | Skip low-confidence healing suggestions |

### Observability (both Playwright frameworks)

| Item | Effort | Description |
|---|---|---|
| Grafana dashboard | Medium | SQLite backend + Grafana panels |
| Trend analysis | Medium | Compare metrics across runs |
| Flake detection rules | Small | Configurable flake rate thresholds/alerts |

---

## Environment Variables (all modules, all providers)

All variables default to disabled. Zero overhead when not configured.

### Provider-agnostic (module-level)

| Variable | Default | Module |
|---|---|---|
| `OBSERVABILITY_ENABLED` | `false` | Observability |
| `AUTO_BUG_ENABLED` | `false` | Defect Management |
| `AUTO_BUG_PROVIDER` | — | Defect Management |
| `AUTO_BUG_RESOLVE` | `false` | Defect Management |
| `AUTO_BUG_BRANCH` | `main` | Defect Management |
| `AI_HEALING_ENABLED` | `false` | Self-Healing |

### Jira adapter

| Variable | Default | Modules |
|---|---|---|
| `JIRA_ENABLED` | `false` | TCM, Defect Mgmt |
| `JIRA_BASE` | — | All Jira modules |
| `JIRA_USER` | — | All Jira modules |
| `JIRA_TOKEN` | — | All Jira modules |
| `JIRA_JQL` | — | Requirements Analysis, Code Gen |
| `JIRA_DRY_RUN` | `false` | All Jira modules |
| `JIRA_TRANSITION_ON_PASS` | — | TCM |
| `JIRA_TRANSITION_ON_FAIL` | — | TCM |

### Zephyr Scale adapter

| Variable | Default | Modules |
|---|---|---|
| `ZEPHYR_ENABLED` | `false` | TCM |
| `ZEPHYR_API_TOKEN` | — | TCM |
| `ZEPHYR_BASE_URL` | `https://api.zephyrscale.smartbear.com/v2` | TCM |
| `ZEPHYR_PROJECT_KEY` | — | TCM |
| `ZEPHYR_DRY_RUN` | `false` | TCM |

### LLM providers

| Variable | Default | Modules |
|---|---|---|
| `OLLAMA_MODEL` | `llama3.1:8b` | Self-Healing, Code Gen |
| `OLLAMA_HOST` | `http://localhost:11434` | Self-Healing, Code Gen |
| `OPENAI_API_KEY` | — | Code Gen |
| `ANTHROPIC_API_KEY` | — | Code Gen |

---

## Implementation Order

### Phase 1: Validate what exists (1-2 days)

1. Set up free Atlassian developer instance
2. Add Zephyr Scale trial
3. Run test-forge `--create` paths against real instances
4. Fix issues found
5. Document working API patterns

### Phase 2: Build defect management + Zephyr reporting (3-5 days)

1. Zephyr execution reporters in both Playwright frameworks
2. Bug auto-creation/resolution in both Playwright frameworks
3. Provider abstraction interface for defect management
4. CI workflow updates

### Phase 3: End-to-end composition (1-2 days)

1. Full Jira + Zephyr workflow demo (story → AC validation → test doc → Zephyr TCs → code gen → execution → reporting)
2. Full no-tools workflow demo (local file → test doc → code gen → execution → observability)
3. Document both for conference talk / blog post

### Phase 4: Expand adapters (ongoing)

1. TestRail adapter for TCM
2. GitHub Issues adapter for defect management
3. Azure DevOps adapter for requirements + defect management
4. TypeScript code generation mode
5. Grafana observability dashboard
