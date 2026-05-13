# Enhancement: Modular QA Platform

## Vision

An always-on, modular QA platform covering the entire testing lifecycle. A Node.js server orchestrates independent modules — from requirement analysis through execution, healing, and reporting. Each module works standalone or composes into end-to-end workflows. No module assumes a specific project management tool, test case manager, CI provider, or target platform.

Teams pick the modules they need. The server runs continuously — ingesting new requirements, validating AC, generating and running tests, exploring the application, and reporting results.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        QA Platform Server                            │
│                        (Node.js / Fastify)                           │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                      INTAKE LOOP                             │    │
│  │  Jira poll · Confluence watch · GitHub webhooks · API specs  │    │
│  └────────────────────────┬─────────────────────────────────────┘    │
│                           ▼                                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐     │
│  │ Requirements │ │ Test Design │ │ Test Case   │ │ Code Gen  │     │
│  │ Analysis     │ │             │ │ Management  │ │           │     │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └─────┬─────┘     │
│         │               │               │              │            │
│  ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐ ┌────▼──────┐    │
│  │ Execution   │ │ Self-Healing│ │ Defect Mgmt │ │ Observ.   │    │
│  │ (multi-plat)│ │             │ │             │ │ & Analytics│    │
│  └─────────────┘ └─────────────┘ └─────────────┘ └───────────┘     │
│                                                                      │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────┐ ┌────────────┐   │
│  │ Visual      │ │ API Testing │ │ Exploratory  │ │ Mobile     │   │
│  │ Regression  │ │             │ │ Testing      │ │ Testing    │   │
│  └─────────────┘ └─────────────┘ └──────────────┘ └────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                    FEEDBACK LOOP                              │    │
│  │  Zephyr update · GitHub comment · Jira transition · Slack    │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                    DASHBOARD                                  │    │
│  │  Flake rate · MTTD · Coverage · Heal log · Visual diffs      │    │
│  └──────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

Each module has its own integration adapters. Jira is one adapter. Azure DevOps, Linear, GitHub Issues, TestRail, or plain files are others.

---

## Server Architecture

### Runtime

**Node.js + Fastify** — natural fit since the primary execution engine (playwright-ai-framework-ts) is already TypeScript. The server provides:

- **REST API** for manual triggers and external integrations
- **Webhook endpoints** for Jira, GitHub, Confluence event-driven intake
- **Job queue** (BullMQ on Redis) for scheduling test runs, polling cycles, exploratory sessions, and async work
- **WebSocket** for live dashboard updates

### Server Modes

| Mode | Description |
|---|---|
| **Watch** | Polls Jira/Confluence on interval. Reacts to new/changed stories. Validates AC, generates BDD, queues test generation. |
| **Execute** | Runs test suites on schedule, on trigger (PR, deploy, webhook), or on demand. Reports results. |
| **Explore** | Launches AI-driven exploratory testing sessions. Autonomously navigates the app, logs findings, creates defect tickets. |
| **Report** | Aggregates metrics, generates dashboards, pushes summaries to Slack/email/Jira. |

All modes run concurrently. The server is always doing all four.

### Job Queue Design

```
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  Intake Jobs  │     │ Execution Jobs│     │ Reporting Jobs│
│               │     │               │     │               │
│ poll-jira     │     │ run-suite     │     │ update-zephyr │
│ poll-confluence│    │ run-single    │     │ comment-jira  │
│ process-webhook│    │ explore-app   │     │ comment-github│
│ validate-ac   │     │ visual-diff   │     │ push-metrics  │
│ generate-bdd  │     │ api-contract  │     │ send-slack    │
└───────┬───────┘     └───────┬───────┘     └───────┬───────┘
        │                     │                     │
        └─────────────────────┴─────────────────────┘
                              │
                     ┌────────▼────────┐
                     │  Redis (BullMQ) │
                     └─────────────────┘
```

### Existing Code That Becomes the Server

| Server Component | Current Source | Repo |
|---|---|---|
| Intake loop (Jira polling) | `src/poller/jira_poller_with_validation.py` | automated-test-generation-framework |
| AC validation | `/jira-clarify`, `/confluence-clarify` skills | test-forge |
| BDD generation | `/confluence-breakdown` skill | test-forge |
| Test design | `/jira-test-gen`, `/confluence-test-gen` skills | test-forge |
| Test code generation | `src/generators/` (template, LLM, hybrid) | automated-test-generation-framework |
| Execution engine | Playwright test runner | playwright-ai-framework-ts |
| Self-healing | `utils/ai-healing.ts` | playwright-ai-framework-ts |
| Observability | `utils/test-observability.ts` | playwright-ai-framework-ts |
| Jira reporting | `utils/jira-client.ts` | playwright-ai-framework-ts |
| Exploratory testing | AI-driven navigation | ai-exploratory-testing-tool (rudimentary) |

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

**What it does:** Takes BDD scenarios from test design and generates executable test code. Sources include existing test code patterns, exploratory Playwright recordings, manual SDET work, or a combination. Validates generated code structurally before saving.

**Generation flow:**

```
BDD Scenarios (Given/When/Then)
    │
    ├─ Match against knowledge base (existing page objects, flows)
    ├─ Reference exploratory session recordings
    ├─ Reference manual SDET-authored test patterns
    │
    ▼
Generated Playwright test code
    │
    ├─ Structural validation (AST parse, import check)
    ├─ TCM key annotation (ZEPH-T801 in test name)
    │
    ▼
Ready for execution
```

**Generation modes:**

| Mode | How | Tradeoff |
|---|---|---|
| Template | Predefined code templates + knowledge base selectors | Fast, deterministic, no API cost |
| LLM | OpenAI, Claude, Ollama, Azure | Intelligent, handles ambiguity, costs tokens |
| Hybrid | LLM first, template fallback | Best of both |

**Knowledge base:** JSON schema of page objects (selectors), test flows (step sequences), and test data. Updated automatically by indexing existing GitHub repos and from exploratory session recordings.

**Supported frameworks:**

| Framework | Language | Status |
|---|---|---|
| Playwright + pytest | Python | Built |
| Playwright + @playwright/test | TypeScript | Planned |
| Cypress | JavaScript | Planned |
| Selenium | Java/Python | Planned |
| Appium | TypeScript/Java | Planned (mobile native) |
| Detox | TypeScript | Planned (React Native) |

**Where it lives:** `automated-test-generation-framework`

---

### 5. Test Execution

**What it does:** Runs tests with retries, parallel execution, multi-browser/multi-platform support, and cloud execution. Records structured metrics for every test run.

**Platform adapters:**

| Platform | Adapter | How | Status |
|---|---|---|---|
| Web (desktop) | Playwright | Chromium, Firefox, WebKit | Built |
| Mobile web | Playwright + device emulation | Viewport + UA emulation | Built |
| Mobile web (real devices) | Playwright + BrowserStack | Real device cloud | Built |
| Native mobile (iOS) | Appium + XCUITest | Native app automation | Not built |
| Native mobile (Android) | Appium + Espresso/UiAutomator2 | Native app automation | Not built |
| React Native | Detox | JS-native testing | Not built |

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
| Mobile device emulation | Available | Available |

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`

---

### 6. AI Self-Healing

**What it does:** When a test fails after all retries, queries a local or remote LLM to analyze the failure. Produces structured healing reports with root cause analysis, confidence scores, and suggested fixes. Optionally generates a corrected test file. Comments on the linked Zephyr case or GitHub PR when code is updated via healing.

**Healing flow:**

```
Test failure (all retries exhausted)
    │
    ▼
Capture context: DOM snapshot / view hierarchy, error, screenshot
    │
    ▼
Query LLM: "Find the element, suggest new locator"
    │
    ├─ Confidence ≥ threshold → Apply fix, re-run, log heal event
    │   ├─ Comment on Zephyr test case (if linked)
    │   └─ Comment on GitHub PR (if in PR context)
    │
    └─ Confidence < threshold → Log as unhealed, create defect ticket
```

**LLM providers:**

| Provider | Status |
|---|---|
| Ollama (local) | Built — both frameworks |
| Claude API | Planned |
| OpenAI API | Planned |

**Cross-platform healing:**

| Platform | UI Tree Source | Locator Types |
|---|---|---|
| Web | DOM (`page.content()`) | CSS, XPath, data-testid, text |
| Mobile native (iOS) | Accessibility hierarchy (`getPageSource()`) | Accessibility ID, predicate string, class chain |
| Mobile native (Android) | View hierarchy (`getPageSource()`) | Resource ID, accessibility ID, XPath, UiSelector |

The LLM doesn't care about the platform — it's always "here's a tree of labeled nodes, find this element." The capture method and locator syntax differ; the healing logic is the same.

**What needs building:**
- Configurable model selection (currently hardcoded to `llama3.1:8b`)
- Confidence threshold enforcement
- Heal-and-alert pattern: successful healing creates a TODO for human review
- Feed healing results into observability metrics
- Comment on Zephyr case / GitHub PR when healing updates test code

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

**What it does:** Records structured per-test metrics. Tracks flake rate, pass rate, MTTD, execution cost, slowest tests, and error categorization. Powers the always-on dashboard.

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
| platform | web, mobile-web, ios-native, android-native |
| commit_sha | Git commit (auto-detected) |
| branch | Git branch (auto-detected) |
| heal_event | Whether AI healing triggered |
| error_category | timeout, element-not-found, navigation, assertion, browser-crash, other |

**Dashboard panels:**

| Panel | Data Source | Purpose |
|---|---|---|
| Flake rate trend | Time-series pass/fail per test | Identify unstable tests |
| MTTD by module | Time from deploy to first failure detected | Measure detection speed |
| CI cost per suite | Duration × runner cost | Optimize execution budget |
| Defect escape rate | Bugs found in prod vs caught by tests | Measure effectiveness |
| Heal log | Self-healing events over time | Track automation vs manual fixes |
| Visual diff gallery | Side-by-side screenshot comparisons | Review visual regressions |
| API contract status | Pass/fail per endpoint per env | Monitor API health |
| Exploratory findings | AI-discovered issues by severity | Measure exploration value |

**Outputs:**

| Output | Format | Status |
|---|---|---|
| Per-test metrics | JSONL | Built — both frameworks |
| Summary | JSON | Built — both frameworks |
| Markdown report | Markdown | Built — both frameworks |
| CI artifact upload | GitHub Actions | Built — both frameworks |
| Live dashboard | WebSocket → browser | Planned (server feature) |
| Grafana integration | SQLite → Grafana | Planned |
| Trend analysis | Time-series over multiple runs | Planned |

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`, server dashboard

---

### 9. Visual Regression

**What it does:** Pixel-level screenshot comparison against baselines. First run saves baseline; subsequent runs compare and fail if diff exceeds tolerance. Generates diff images highlighting changes.

| Aspect | Python Framework | TS Framework |
|---|---|---|
| Library | OpenCV + NumPy | pixelmatch + pngjs (or Playwright built-in `toHaveScreenshot()`) |
| Native deps | Yes (opencv-python) | No (pure JS with built-in option) |
| Element-level | Yes | Yes |
| Full-page | Yes | Yes |
| Tolerance config | Yes | Yes |
| Diff images | Yes | Yes |

**Multi-platform visual testing:**

| Platform | Approach | Baseline Strategy |
|---|---|---|
| Desktop web | Playwright screenshot at standard viewports (1280, 1440, 1920) | One baseline per viewport |
| Mobile web | Device emulation screenshots (iPhone, Pixel, iPad) | One baseline per device profile |
| Mobile web (real devices) | BrowserStack screenshot API | One baseline per reference device per form factor |
| Native mobile | Appium screenshot | One baseline per reference device per OS version |

**Baseline grouping:** Test on a reference device per form factor, not every device in the farm. The visual diff matrix explodes with mobile (dozens of device/OS combos). Smart grouping keeps it manageable:
- Phone portrait: iPhone 15 Pro as reference
- Phone landscape: same device rotated
- Tablet: iPad Air as reference
- Android: Pixel 8 as reference

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`

---

### 10. API Testing

**What it does:** Generates and executes API tests from OpenAPI/Swagger specifications. Validates contracts, tests error handling, and monitors API health across environments.

**Two layers:**

| Layer | Source | What It Tests |
|---|---|---|
| Contract tests | OpenAPI/Swagger spec | Response schema matches spec, status codes correct, required fields present |
| Scenario tests | BDD acceptance criteria | Business logic flows via API (create → read → update → delete) |

**Generation flow:**

```
OpenAPI/Swagger spec (URL or file)
    │
    ▼
Parse endpoints, schemas, auth requirements
    │
    ├─ Generate contract tests (every endpoint, every status code)
    ├─ Generate scenario tests from BDD AC
    │
    ▼
Playwright request API (no separate HTTP client needed)
    │
    ▼
Results → observability + Zephyr/Jira reporting
```

**Capabilities:**

| Capability | Status |
|---|---|
| Mock GET/POST/PUT/DELETE by URL pattern | Built (both frameworks) |
| Load mock data from files | Built (both frameworks) |
| Simulate network failures and slow responses | Built (both frameworks) |
| Response templates (success, 401, 404, 500, etc.) | Built (both frameworks) |
| Request/response logging | Built (both frameworks) |
| OpenAPI spec parsing → contract test generation | Not built |
| Schema validation against spec | Not built |
| Multi-environment execution (dev, staging, prod) | Not built |
| API health monitoring (scheduled) | Not built (server feature) |

**Where it lives:** `playwright-ai-framework`, `playwright-ai-framework-ts`

---

### 11. Exploratory Testing

**What it does:** AI-driven autonomous exploration of the application under test. Navigates the app without predefined scripts, discovers UI states, identifies potential issues, and feeds findings back into the defect management module.

**Exploration modes:**

| Mode | Description | Use Case |
|---|---|---|
| Free roam | Navigate every reachable page, click every interactive element | New app or major release — discover what's there |
| Guided charter | Follow an exploratory test charter (from test design module) | Targeted exploration of a specific feature area |
| Regression hunt | Focus on recently changed areas (from git diff or Jira changelog) | Post-deploy validation |

**What the explorer captures:**

| Artifact | Purpose |
|---|---|
| Page inventory | Map of all discovered pages/routes |
| Interaction log | Every click, input, navigation — full session recording |
| Anomalies | Console errors, broken images, dead links, layout shifts |
| Screenshots | Visual record at each state transition |
| Network errors | Failed API calls, unexpected status codes |
| Accessibility issues | WCAG violations found during exploration |
| Performance markers | Slow page loads, unresponsive elements |

**Defect creation from exploration:**

```
Explorer finds console error on /checkout page
    │
    ▼
Capture: screenshot, console log, network state, reproduction steps
    │
    ▼
Create defect ticket (Jira/GitHub/Linear) with full context
    │
    ▼
Link to exploratory session recording for reproduction
```

**Current state:** `ai-exploratory-testing-tool` repo exists but is rudimentary. Needs significant enhancement to become a full module:
- Smarter navigation strategy (not just random clicking)
- State machine awareness (login → authenticated pages, form flows)
- Integration with defect management module
- Session recording and playback
- Charter-driven exploration from test design output

**Where it lives:** `ai-exploratory-testing-tool` → folds into platform server

---

### 12. Contract Testing

**What it does:** Consumer-driven contract testing for microservice architectures. Different from API schema validation (Module 10) — contract testing verifies that a provider service still satisfies what its consumer services actually depend on.

**Two approaches:**

| Approach | Tool | How It Works |
|---|---|---|
| Consumer-driven (Pact) | Pact.js / Pact-Python | Consumer defines expected interactions → provider verifies against them |
| Schema-first | OpenAPI diff | Compare current spec to previous version → detect breaking changes |

**Why both matter:**

- **Schema validation** (Module 10): "Does the API return what its spec says?" — catches implementation bugs
- **Contract testing** (this module): "Does the API still return what Service B depends on?" — catches breaking changes between services

**Flow:**

```
Consumer service defines contract
    │ "I call GET /users/123 and expect {id, name, email}"
    ▼
Contract published to broker (Pact Broker or S3)
    │
    ▼
Provider CI runs contract verification
    │ "Do I still satisfy what consumers expect?"
    │
    ├─ Pass → deploy safe
    └─ Fail → breaking change detected, block deploy, notify
```

**Capabilities:**

| Capability | Status |
|---|---|
| Pact consumer test generation from BDD AC | Not built |
| Pact provider verification in CI | Not built |
| Pact Broker integration | Not built |
| OpenAPI spec diff (breaking change detection) | Not built |
| Contract status in dashboard | Not built |

**Where it lives:** New module in platform server + CI integration

---

### 13. Test Data Management

**What it does:** Manages the full test data lifecycle — generation, seeding, isolation, teardown, and masking. Test data is the #1 reason tests are flaky or unmaintainable. This module makes data a first-class concern.

**Capabilities:**

| Capability | Description | Status |
|---|---|---|
| Data factories | Generate synthetic test data per entity (users, orders, products) with realistic values | Not built |
| Seed/teardown | Populate DB before test suite, clean up after — transaction rollback or explicit delete | Not built |
| Data isolation | Each test gets its own data scope — no cross-test contamination | Not built |
| PII masking | Clone prod-like data with PII replaced (names, emails, SSNs, addresses) | Not built |
| Environment-aware | Different data sources per environment (local SQLite, dev Postgres, staging snapshot) | Not built |
| Fixture files | JSON/YAML fixtures checked into repo, loaded at test time | Partial (both frameworks have basic fixture support) |
| Dynamic generation | Faker.js / Faker-py for realistic random data | Not built (as module) |

**Data factory pattern:**

```typescript
const user = TestData.create('user', {
  role: 'admin',
  status: 'active',
  // everything else auto-generated with realistic values
});

const order = TestData.create('order', {
  userId: user.id,
  items: 3,
  // generates 3 random products, calculates totals
});
```

**Environment variables:**

| Variable | Default | Description |
|---|---|---|
| `TEST_DATA_STRATEGY` | `fixture` | `fixture`, `factory`, `snapshot`, `prod-masked` |
| `TEST_DATA_SEED_DB` | `false` | Seed database before suite |
| `TEST_DATA_CLEANUP` | `true` | Clean up after suite |
| `TEST_DATA_ISOLATION` | `transaction` | `transaction` (rollback), `delete` (explicit), `none` |
| `DB_CONNECTION_STRING` | — | Database connection for seed/teardown |

**Where it lives:** New shared module used by both Playwright frameworks

---

### 14. Security Testing

**What it does:** Automated security scanning integrated into the test pipeline. Covers OWASP Top 10 at minimum. Runs DAST scans during test execution, dependency vulnerability scanning, and generates security-focused test cases from requirements.

**Layers:**

| Layer | Tool | What It Catches | When It Runs |
|---|---|---|---|
| DAST (Dynamic) | OWASP ZAP (headless) | XSS, injection, broken auth, CSRF, misconfigs | During test execution or as server job |
| Dependency scanning | npm audit / pip-audit / Snyk | Known CVEs in dependencies | CI on every commit |
| Secret scanning | gitleaks / trufflehog | Hardcoded credentials in code | Pre-commit hook + CI |
| Security test generation | LLM + OWASP checklist | Security-specific test scenarios from requirements | During test design (Module 2) |
| Header analysis | Custom checks | Missing security headers (HSTS, CSP, X-Frame-Options) | During API/web test execution |

**OWASP Top 10 coverage:**

| OWASP Category | Test Approach |
|---|---|
| A01: Broken Access Control | Auth bypass tests, role escalation, IDOR checks |
| A02: Cryptographic Failures | TLS validation, sensitive data exposure in responses |
| A03: Injection | SQL injection, XSS, command injection via form inputs |
| A04: Insecure Design | Business logic abuse scenarios from AC inversion |
| A05: Security Misconfiguration | Header checks, default credentials, exposed endpoints |
| A06: Vulnerable Components | Dependency scanning (npm audit / pip-audit) |
| A07: Authentication Failures | Brute force, credential stuffing, session fixation |
| A08: Software/Data Integrity | CSP validation, SRI checks |
| A09: Logging Failures | Verify security events are logged (failed logins, access denials) |
| A10: SSRF | Internal network access via user-controlled URLs |

**Integration with test design:**

When Module 2 (Test Design) generates the 12-section test document, Section 6 (Error Conditions) and Section 7 (Negative Tests) should include OWASP-derived scenarios. The security module provides a checklist that feeds into test design.

**Environment variables:**

| Variable | Default | Description |
|---|---|---|
| `SECURITY_SCAN_ENABLED` | `false` | Enable DAST scanning |
| `ZAP_HOST` | `http://localhost:8080` | OWASP ZAP proxy address |
| `ZAP_API_KEY` | — | ZAP API key |
| `DEPENDENCY_SCAN_ENABLED` | `true` | Run dependency vulnerability scan |
| `SECRET_SCAN_ENABLED` | `true` | Run secret detection |
| `SECURITY_SEVERITY_THRESHOLD` | `medium` | Minimum severity to fail tests (`low`, `medium`, `high`, `critical`) |

**Where it lives:** New module — DAST integration in both Playwright frameworks, dependency/secret scanning in CI configs

---

### 15. Database Validation

**What it does:** Validates the data layer directly. Tests don't just check that the API returned 200 — they verify the data was actually persisted correctly, schema migrations ran cleanly, and data integrity constraints hold.

**Capabilities:**

| Capability | Description | Status |
|---|---|---|
| Post-operation verification | After API call, query DB to verify data was persisted correctly | Not built |
| Schema migration testing | Run migrations on clean DB, verify schema matches expected state | Not built |
| Data integrity checks | Verify foreign keys, unique constraints, not-null constraints hold after operations | Not built |
| Query performance validation | Flag queries exceeding duration threshold (slow query detection) | Not built |
| Referential integrity | Verify cascading deletes, orphan prevention after operations | Not built |
| Snapshot comparison | Compare DB state before/after operation, verify only expected changes | Not built |

**Flow:**

```
Test action (e.g., POST /users creates a user)
    │
    ├─ API returns 201 (Module 5 verifies this)
    │
    ▼
DB validation (this module)
    │
    ├─ Query users table: row exists with correct values?
    ├─ Query audit_log table: creation event recorded?
    ├─ Query related tables: no orphaned records?
    │
    ▼
Pass/fail — catches bugs where API returns success but data is wrong
```

**Supported databases:**

| Database | Driver | Status |
|---|---|---|
| PostgreSQL | pg (Node.js) / psycopg2 (Python) | Not built |
| MySQL | mysql2 (Node.js) / mysqlclient (Python) | Not built |
| SQLite | better-sqlite3 (Node.js) / sqlite3 (Python) | Not built |
| MongoDB | mongodb (Node.js) / pymongo (Python) | Not built |
| SQL Server | mssql (Node.js) / pyodbc (Python) | Not built |

**Environment variables:**

| Variable | Default | Description |
|---|---|---|
| `DB_VALIDATION_ENABLED` | `false` | Enable database validation |
| `DB_VALIDATION_CONNECTION` | — | Connection string for validation queries |
| `DB_VALIDATION_READONLY` | `true` | Only SELECT queries allowed (safety) |
| `DB_QUERY_TIMEOUT_MS` | `5000` | Max query duration before flagging |
| `DB_MIGRATION_PATH` | — | Path to migration files for schema testing |

**Where it lives:** New shared module used by both Playwright frameworks

---

### 16. CI Server Integration

**What it does:** Provides CI-agnostic test runners and configuration templates for every major CI platform. The platform shouldn't assume GitHub Actions — Jenkins, GitLab CI, CircleCI, Azure Pipelines, and TeamCity are all common in enterprise.

**CI platform support:**

| Platform | Config File | Status |
|---|---|---|
| GitHub Actions | `.github/workflows/*.yml` | Built (both frameworks) |
| Jenkins | `Jenkinsfile` | Not built |
| GitLab CI | `.gitlab-ci.yml` | Not built |
| CircleCI | `.circleci/config.yml` | Not built |
| Azure Pipelines | `azure-pipelines.yml` | Not built |
| TeamCity | `.teamcity/settings.kts` | Not built |
| Bitbucket Pipelines | `bitbucket-pipelines.yml` | Not built |

**What each CI config provides:**

| Stage | Purpose |
|---|---|
| Install | Dependencies, browsers, Playwright install |
| Lint + type check | Static analysis gate |
| Unit tests | Fast feedback |
| Smoke tests | Core path validation |
| Full suite | Complete test execution |
| Security scan | Dependency + secret scanning |
| Observability upload | Metrics artifact collection |
| Report | Zephyr/Jira/GitHub result posting |

**CI-agnostic runner:**

The platform should provide a single `npx qa-platform run` command that works identically regardless of CI platform. The CI config just calls this command. Environment variables control behavior.

```yaml
# Jenkins example
pipeline {
  stages {
    stage('Test') {
      steps {
        sh 'npx qa-platform run --suite smoke --report zephyr'
      }
    }
  }
}
```

```yaml
# GitLab CI example
test:
  script:
    - npx qa-platform run --suite smoke --report zephyr
```

**Environment variables:**

| Variable | Default | Description |
|---|---|---|
| `CI_PLATFORM` | auto-detect | `github`, `jenkins`, `gitlab`, `circleci`, `azure`, `teamcity` |
| `CI_ARTIFACT_PATH` | `test_artifacts/` | Where to write artifacts for CI collection |
| `CI_PARALLEL_SHARDS` | `1` | Number of parallel shards |
| `CI_FAIL_FAST` | `false` | Stop on first failure |

**Where it lives:** Platform server CLI + template configs per CI platform

---

### 17. Mobile Testing

**What it does:** Extends the platform to native iOS and Android app testing. The upstream modules (requirements analysis, test design, BDD generation) are platform-agnostic — they don't change. Mobile testing adds native execution adapters and mobile-specific concerns.

**Same pipeline, different execution target:**

```
Confluence spec → AC gate → BDD scenarios → ┬→ Playwright (web)
                                             ├→ Playwright + device emulation (mobile web)
                                             ├→ Appium (native iOS/Android)
                                             ├→ Detox (React Native)
                                             └→ Espresso/XCUITest (platform-native)
```

**Platform comparison:**

| Concern | Web (built) | Mobile Native (planned) |
|---|---|---|
| Locator strategy | CSS selectors, data-testid | Accessibility IDs, resource-id, XPath |
| Self-healing input | DOM snapshot | View hierarchy snapshot (same LLM pattern) |
| Visual diffing | Browser screenshot (3-5 viewports) | Device screenshot (smart baseline grouping) |
| Code generation | Playwright API | Appium WebDriver / Detox API |
| Device matrix | BrowserStack browsers | BrowserStack App Automate / device farm |
| API layer | Playwright `request` API | Same — API testing is platform-agnostic |

**Execution adapters needed:**

| Adapter | Framework | Target | Status |
|---|---|---|---|
| Playwright | @playwright/test | Web (desktop + mobile web) | Built |
| BrowserStack Web | Playwright + BrowserStack | Real mobile browsers | Built |
| Appium iOS | WebdriverIO + Appium | Native iOS apps | Not built |
| Appium Android | WebdriverIO + Appium | Native Android apps | Not built |
| BrowserStack App | Appium + BrowserStack App Automate | Real device farm | Not built |
| Detox | Detox | React Native apps | Not built |

**Where it lives:** `playwright-ai-framework-ts` (web adapters), new `mobile-testing-adapter` module (native adapters)

---

## Module Count: 17

| # | Module | Primary Repo | Status |
|---|---|---|---|
| 1 | Requirements Analysis | test-forge | Built |
| 2 | Test Design | test-forge | Built |
| 3 | Test Case Management | test-forge + Playwright frameworks | Partial |
| 4 | Code Generation | automated-test-generation-framework | Built (Python) |
| 5 | Execution | Playwright frameworks | Built (web) |
| 6 | Self-Healing | Playwright frameworks | Built (basic) |
| 7 | Defect Management | Playwright frameworks | Partial |
| 8 | Observability | Playwright frameworks | Built |
| 9 | Visual Regression | Playwright frameworks | Built |
| 10 | API Testing | Playwright frameworks | Partial (mocking built, contract gen not) |
| 11 | Exploratory Testing | ai-exploratory-testing-tool | Rudimentary |
| 12 | Contract Testing | New | Not built |
| 13 | Test Data Management | New | Not built |
| 14 | Security Testing | New | Not built |
| 15 | Database Validation | New | Not built |
| 16 | CI Server Integration | Playwright frameworks | Partial (GitHub Actions only) |
| 17 | Mobile Testing | New | Not built (web emulation exists) |

---

## How the Repos Map to Modules

| Module | test-forge | automated-test-gen | playwright-ai (Py) | playwright-ai (TS) | ai-exploratory | Platform Server |
|---|---|---|---|---|---|---|
| Requirements Analysis | Primary | — | — | — | — | Intake loop |
| Test Design | Primary | — | — | — | — | Intake loop |
| Test Case Management | Creation | — | Result reporting | Result reporting | — | Feedback loop |
| Code Generation | — | Primary | — | — | — | Job queue |
| Execution | — | — | Primary | Primary | — | Job queue |
| Self-Healing | — | — | Primary | Primary | — | Job queue |
| Defect Management | — | — | Primary | Primary | — | Feedback loop |
| Observability | — | — | Primary | Primary | — | Dashboard |
| Visual Regression | — | — | Primary | Primary | — | Dashboard |
| API Testing | — | — | Primary | Primary | — | Job queue |
| Exploratory Testing | — | — | — | — | Primary | Job queue |
| Contract Testing | — | — | — | — | — | Job queue + CI |
| Test Data Management | — | — | Shared module | Shared module | — | — |
| Security Testing | — | — | Integration | Integration | — | Job queue |
| Database Validation | — | — | Shared module | Shared module | — | — |
| CI Server Integration | — | — | Config templates | Config templates | — | CLI runner |
| Mobile Testing | — | — | — | Partial (web) | — | Job queue |

---

## Example Compositions

### Composition 1: Full Jira + Zephyr Enterprise Workflow

```
Confluence specification
    │
    ▼
[Server: Intake Loop — Confluence watcher]
    │
    ▼
[Module 1: Requirements Analysis]
    │ via /confluence-clarify
    │ Posts feedback if spec has gaps
    ▼
[Module 2: Test Design]
    │ via /confluence-breakdown → stories with BDD AC
    │ via /confluence-test-gen → 12-section test doc
    ▼
Stories created in Jira
    │
    ▼
[Module 1: Requirements Analysis — AC gate]
    │ via /jira-clarify
    │ Validates each story's AC, comments if not ready
    ▼
[Module 3: Test Case Management]
    │ via /jira-test-gen --create
    │ Zephyr Scale test cases created, linked to story
    ▼
[Module 4: Code Generation]
    │ BDD + knowledge base + exploratory recordings → Playwright code
    │ Tests annotated with ZEPH-* keys
    ▼
[Module 5: Execution] + [Module 6: Self-Healing]
    │ Server execute mode — runs on schedule + PR trigger
    │ Healing fires, comments on Zephyr case if code updated
    ▼
[Module 9: Visual Regression]
    │ Baseline comparison, diff images generated
    ▼
[Module 10: API Testing]
    │ Contract tests from OpenAPI spec
    │ Scenario tests from BDD AC
    ▼
[Module 7: Defect Management]
    │ Auto-create bugs in Jira on main-branch failures
    │ Auto-resolve when tests pass again
    ▼
[Module 8: Observability]
    │ Metrics recorded, dashboard updated in real-time
    ▼
[Module 3: Test Case Management — result reporting]
    │ Zephyr test cycle updated with pass/fail per test case
    │ Story gets summary comment
    ▼
[Module 11: Exploratory Testing]
    │ Server explore mode — autonomous sessions on new features
    │ Findings → defect tickets + exploratory session recordings
    ▼
Dashboard shows: coverage, flake rate, bug burn-down, visual diffs, API health, exploration findings
```

### Composition 2: No Project Management Tool

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
[Module 5: Execution] + [Module 6: Self-Healing]
    │ pytest / npx playwright test
    ▼
[Module 8: Observability]
    │ metrics.jsonl + report.md
    ▼
Done — no Jira, no Zephyr, no cloud services
```

### Composition 3: Mobile App Testing

```
Jira story with AC for mobile feature
    │
    ▼
[Module 1: Requirements Analysis] — same as web
    │
    ▼
[Module 2: Test Design] — same as web (BDD is platform-agnostic)
    │
    ▼
[Module 4: Code Generation]
    │ Generates Appium test code instead of Playwright
    │ Uses accessibility IDs as primary locator strategy
    ▼
[Module 5: Execution — mobile adapter]
    │ Appium + BrowserStack App Automate (real device farm)
    ▼
[Module 6: Self-Healing]
    │ View hierarchy snapshot → LLM → new accessibility ID locator
    ▼
[Module 9: Visual Regression]
    │ Smart baseline grouping: one reference device per form factor
    ▼
[Module 7: Defect Management] + [Module 8: Observability]
    │ Same as web — platform field added to metrics
    ▼
Dashboard: same panels, filtered by platform
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
| `EXPLORATORY_ENABLED` | `false` | Exploratory Testing |
| `VISUAL_REGRESSION_ENABLED` | `false` | Visual Regression |
| `API_CONTRACT_ENABLED` | `false` | API Testing |

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
| `OLLAMA_MODEL` | `llama3.1:8b` | Self-Healing, Code Gen, Exploratory |
| `OLLAMA_HOST` | `http://localhost:11434` | Self-Healing, Code Gen, Exploratory |
| `OPENAI_API_KEY` | — | Code Gen, Exploratory |
| `ANTHROPIC_API_KEY` | — | Code Gen, Exploratory |

### API testing

| Variable | Default | Modules |
|---|---|---|
| `OPENAPI_SPEC_URL` | — | API Testing |
| `OPENAPI_SPEC_FILE` | — | API Testing |
| `API_BASE_URL` | — | API Testing |
| `API_AUTH_TOKEN` | — | API Testing |

### Contract testing

| Variable | Default | Modules |
|---|---|---|
| `PACT_ENABLED` | `false` | Contract Testing |
| `PACT_BROKER_URL` | — | Contract Testing |
| `PACT_BROKER_TOKEN` | — | Contract Testing |
| `PACT_PROVIDER_NAME` | — | Contract Testing |
| `PACT_CONSUMER_NAME` | — | Contract Testing |

### Test data management

| Variable | Default | Modules |
|---|---|---|
| `TEST_DATA_STRATEGY` | `fixture` | Test Data (`fixture`, `factory`, `snapshot`, `prod-masked`) |
| `TEST_DATA_SEED_DB` | `false` | Test Data |
| `TEST_DATA_CLEANUP` | `true` | Test Data |
| `TEST_DATA_ISOLATION` | `transaction` | Test Data (`transaction`, `delete`, `none`) |
| `DB_CONNECTION_STRING` | — | Test Data, DB Validation |

### Security testing

| Variable | Default | Modules |
|---|---|---|
| `SECURITY_SCAN_ENABLED` | `false` | Security |
| `ZAP_HOST` | `http://localhost:8080` | Security (DAST) |
| `ZAP_API_KEY` | — | Security (DAST) |
| `DEPENDENCY_SCAN_ENABLED` | `true` | Security |
| `SECRET_SCAN_ENABLED` | `true` | Security |
| `SECURITY_SEVERITY_THRESHOLD` | `medium` | Security (`low`, `medium`, `high`, `critical`) |

### Database validation

| Variable | Default | Modules |
|---|---|---|
| `DB_VALIDATION_ENABLED` | `false` | DB Validation |
| `DB_VALIDATION_CONNECTION` | — | DB Validation |
| `DB_VALIDATION_READONLY` | `true` | DB Validation |
| `DB_QUERY_TIMEOUT_MS` | `5000` | DB Validation |
| `DB_MIGRATION_PATH` | — | DB Validation |

### CI server

| Variable | Default | Modules |
|---|---|---|
| `CI_PLATFORM` | auto-detect | CI Integration |
| `CI_ARTIFACT_PATH` | `test_artifacts/` | CI Integration |
| `CI_PARALLEL_SHARDS` | `1` | CI Integration |
| `CI_FAIL_FAST` | `false` | CI Integration |

### Mobile testing

| Variable | Default | Modules |
|---|---|---|
| `MOBILE_PLATFORM` | — | Mobile (`ios`, `android`) |
| `APPIUM_HOST` | `http://localhost:4723` | Mobile |
| `APP_PATH` | — | Mobile (path to .app/.apk/.ipa) |
| `DEVICE_NAME` | — | Mobile |
| `PLATFORM_VERSION` | — | Mobile |

### Server

| Variable | Default | Modules |
|---|---|---|
| `SERVER_PORT` | `3030` | Server |
| `REDIS_URL` | `redis://localhost:6379` | Server (BullMQ) |
| `POLL_INTERVAL_MS` | `60000` | Server (intake loop) |
| `EXPLORE_SCHEDULE` | — | Server (cron expression for exploratory sessions) |
| `DASHBOARD_ENABLED` | `true` | Server |

---

## What Needs Building (by module)

### Server (new — the big one)

| Item | Effort | Description |
|---|---|---|
| Fastify server scaffold | Medium | REST API, webhook endpoints, health checks |
| BullMQ job queue | Medium | Redis-backed job scheduling and processing |
| Intake loop (Jira/Confluence poll) | Small | Port from automated-test-gen Python poller |
| Webhook handlers | Medium | Jira, GitHub, Confluence event processing |
| Dashboard UI | Large | Real-time metrics display, visual diff gallery |
| WebSocket live updates | Medium | Push metrics/events to dashboard |

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
| Appium output | Large | Generate mobile test code |
| Generation status reporting | Small | Post status back to source ticket |
| Exploratory recording input | Medium | Use exploration session as generation context |

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
| TCM/PR commenting on heal | Medium | Write-back to Zephyr case or GitHub PR |
| Mobile view hierarchy support | Medium | Parse native app hierarchy for healing |

### Exploratory Testing (ai-exploratory-testing-tool → server)

| Item | Effort | Description |
|---|---|---|
| Smart navigation strategy | Large | State machine awareness, not random clicking |
| Charter-driven exploration | Medium | Accept test design charter as exploration guide |
| Session recording | Medium | Full interaction capture + playback |
| Defect auto-creation from findings | Medium | Console errors, broken UI → defect tickets |
| Accessibility scanning during exploration | Small | WCAG violation detection during roam |
| Integration with server job queue | Medium | Run as scheduled or triggered job |

### API Testing (both Playwright frameworks)

| Item | Effort | Description |
|---|---|---|
| OpenAPI spec parser | Medium | Read spec from URL or file |
| Contract test generation | Large | Generate tests for every endpoint/status code |
| Schema validation | Medium | Response body matches spec schema |
| Multi-environment execution | Small | Same tests against dev/staging/prod |
| API health monitoring | Medium | Scheduled contract checks (server feature) |

### Visual Regression

| Item | Effort | Description |
|---|---|---|
| Baseline diffing with `toHaveScreenshot()` | Small | Use Playwright built-in (TS framework) |
| Diff gallery in dashboard | Medium | Side-by-side visual comparison UI |
| Smart baseline grouping for mobile | Medium | Reference device per form factor |
| Approval workflow | Medium | Mark diffs as intentional vs regression |

### Contract Testing (new module)

| Item | Effort | Description |
|---|---|---|
| Pact consumer test generation | Large | Generate consumer contracts from BDD AC |
| Pact provider verification | Medium | Verify provider against published contracts |
| Pact Broker integration | Medium | Publish/retrieve contracts |
| OpenAPI spec diff | Medium | Detect breaking changes between spec versions |
| Contract status dashboard panel | Small | Pass/fail per consumer-provider pair |

### Test Data Management (new module)

| Item | Effort | Description |
|---|---|---|
| Data factory framework | Large | Entity factories with realistic defaults (Faker.js) |
| Seed/teardown lifecycle | Medium | DB population before suite, cleanup after |
| Data isolation strategy | Medium | Transaction rollback or explicit delete per test |
| PII masking | Medium | Clone prod data with PII replaced |
| Environment-aware data sources | Small | Config-driven per environment |
| Fixture file loader | Small | JSON/YAML fixtures (extend existing basic support) |

### Security Testing (new module)

| Item | Effort | Description |
|---|---|---|
| OWASP ZAP integration | Large | DAST scanning during test execution |
| Dependency scanning in CI | Small | npm audit / pip-audit in all CI configs |
| Secret scanning | Small | gitleaks in pre-commit + CI |
| OWASP Top 10 test generation | Medium | Security checklist feeding into test design |
| Security header validation | Small | Check HSTS, CSP, X-Frame-Options during web tests |
| Security severity gate | Small | Configurable threshold to fail/warn |

### Database Validation (new module)

| Item | Effort | Description |
|---|---|---|
| Post-operation DB verification | Medium | Query DB after API calls to verify persistence |
| Schema migration testing | Medium | Run migrations on clean DB, verify expected state |
| Data integrity checks | Medium | FK, unique, not-null constraint verification |
| Slow query detection | Small | Flag queries exceeding duration threshold |
| Multi-database driver support | Large | Postgres, MySQL, SQLite, MongoDB, SQL Server |

### CI Server Integration (new module)

| Item | Effort | Description |
|---|---|---|
| CI-agnostic runner CLI | Medium | `npx qa-platform run` works on any CI |
| Jenkins pipeline template | Small | Jenkinsfile with all stages |
| GitLab CI template | Small | .gitlab-ci.yml with all stages |
| CircleCI template | Small | .circleci/config.yml |
| Azure Pipelines template | Small | azure-pipelines.yml |
| TeamCity template | Small | settings.kts |
| Parallel shard support | Medium | Split test suite across CI workers |

### Mobile Testing

| Item | Effort | Description |
|---|---|---|
| Appium adapter | Large | WebdriverIO + Appium setup |
| BrowserStack App Automate integration | Medium | Real device farm |
| Mobile-specific page objects | Medium | Accessibility ID-based locator strategy |
| iOS + Android test runners | Large | Platform-specific build/install/run |

---

## Implementation Order

### Phase 1: Validate what exists (1-2 days)

1. Set up free Atlassian developer instance
2. Add Zephyr Scale trial
3. Run test-forge `--create` paths against real instances
4. Fix issues found
5. Document working API patterns

### Phase 2: Server scaffold + defect management (1-2 weeks)

1. Fastify server with BullMQ job queue
2. Intake loop (port Jira poller from Python to TS)
3. Zephyr execution reporters in both Playwright frameworks
4. Bug auto-creation/resolution in both Playwright frameworks
5. Provider abstraction interface for defect management
6. Webhook handlers for Jira + GitHub

### Phase 3: Test data + API testing + visual regression (1-2 weeks)

1. Test data factory framework (Faker.js, entity factories)
2. Seed/teardown lifecycle hooks
3. OpenAPI spec parser + contract test generation
4. Playwright `toHaveScreenshot()` baseline diffing
5. Visual diff gallery in dashboard
6. API health monitoring as server job

### Phase 4: Security + DB validation (1-2 weeks)

1. OWASP ZAP integration (DAST scanning)
2. Dependency scanning in all CI configs
3. OWASP Top 10 checklist feeding into test design module
4. Post-operation DB verification framework
5. Schema migration testing
6. Security header validation

### Phase 5: Contract testing + CI server integration (1 week)

1. Pact consumer test generation from BDD AC
2. Pact provider verification
3. CI-agnostic runner CLI (`npx qa-platform run`)
4. Jenkins, GitLab CI, CircleCI, Azure Pipelines templates
5. Parallel shard support

### Phase 6: Exploratory testing enhancement (1-2 weeks)

1. Smart navigation strategy (state machine, not random)
2. Charter-driven exploration from test design output
3. Session recording and playback
4. Auto-defect creation from exploration findings
5. Integration with server job queue

### Phase 7: Mobile testing (2-3 weeks)

1. Appium adapter for iOS + Android
2. BrowserStack App Automate integration
3. Mobile-specific code generation
4. View hierarchy self-healing
5. Mobile visual baseline grouping

### Phase 8: Dashboard + end-to-end composition (1 week)

1. Real-time dashboard UI
2. Full Jira + Zephyr workflow demo
3. Full no-tools workflow demo
4. Mobile workflow demo
5. Security scan demo
6. Document everything for conference talk / blog post

### Phase 9: Expand adapters (ongoing)

1. TestRail adapter for TCM
2. GitHub Issues adapter for defect management
3. Azure DevOps adapter for requirements + defect management
4. TypeScript code generation mode
5. Linear adapter
6. Pact Broker integration
7. Additional database drivers
