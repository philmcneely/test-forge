# Section: testdata.md
# Loaded on every invocation UNLESS NO_TESTDATA=true.
# Contains Step 6: generate and write the full Test Data Catalogue.
# Do NOT load this file when NO_TESTDATA=true.

---

## Step 6: Generate and write the Test Data Catalogue

**Skip entirely if `NO_TESTDATA=true`.**

Generate `confluence-<SLUG>_testdata.md` with the following structure:

---

**Catalogue file header:**
```
<PAGE_TITLE> — Test Data Catalogue
Source: <CONFLUENCE_URL>
Generated: <date>
Linked Jira tickets: <keys pulled in Step 4b> | none
Environment: [fill in before distributing]
Needed by: [fill in before distributing]

Hand this document to your data setup team. Each section is a list of specific
values or records they need to create in the QA environment before testing begins.
```

---

**Section 1: Baseline Record**

Construct a single known-good record that satisfies every mandatory field in the spec with a valid,
unremarkable value. This is used as the constant backdrop for all single-field variation tests —
testers hold every field constant at the baseline value and swap only the field under test.

```
BASELINE RECORD
  [field name]:  [baseline value]
  [field name]:  [baseline value]
  ...
```

Derive baseline values from:
- Mandatory fields in the spec → use the simplest valid value (e.g. "John" for a first name,
  "123 Main Street" for an address, `"0"` for a binary flag)
- Optional fields → leave empty unless a rule requires them
- Jira ticket descriptions → use any concrete example values mentioned

---

**Section 2: Per-Field Value Tables**

One sub-section per field identified in the spec. For each field:

**Heading:** `### Field: [Field Name] ([Req ID if present]) — [Mandatory/Optional]`

**Context line** (if Jira tickets added rules for this field): `Derived from: [Jira keys]`

**Table:**
```
| # | Test Value | Valid? | Rule | Expected Outcome |
|---|---|---|---|---|
| V1 | [value] | ✅ Valid | [rule ID/description] | Accepted |
| V2 | [value] | ✅ Valid | [rule — boundary passing] | Accepted |
| I1 | [value] | ❌ Invalid | [rule ID/description] | Rejected — [error description] |
| I2 | [value] | ❌ Invalid | [rule] | Rejected |
| B1 | [value] | ⚠️ Boundary | [rule — edge of valid range] | Accepted or Rejected — TBD |
```

Rules for generating rows:
- Every explicit rule in the spec for this field gets at least one row
- Include: minimum valid, maximum valid, one below minimum, one above maximum, empty/null/absent,
  all-same-character, special characters (both allowed and disallowed), consecutive disallowed
  characters, inherited rules from other fields (expand the full rule set)
- For numeric/enum fields: every valid value, every boundary, and representative invalid values
- Mark values needing environment-specific setup with `⚙️ needs env setup`

---

**Section 3: Cross-Field Combo Matrix**

Only generate if the spec contains rules involving two or more fields interacting
(e.g. address cannot equal city, card country must match sender country).

**Heading:** `### Cross-Field Combinations`

**Table:**
```
| # | [Field A] | [Field B] | [Field C if needed] | Rule | Expected |
|---|---|---|---|---|---|
| XF-01 | [value] | [value] | — | [rule ID] | ✅ Accepted |
| XF-02 | [value] | [value] | — | [rule ID] | ❌ Rejected |
```

Each row is a complete record submission — all non-listed fields stay at baseline values.
Flag any combo requiring special environment pre-conditions with `⚙️ needs env setup`.

---

**Section 4: Pre-conditions Checklist**

A checkbox list of everything that must exist in the QA environment before testing can start:

```
### Environment / Infrastructure
- [ ] [condition]

### Accounts / Users
- [ ] [condition]

### Pre-loaded Data
- [ ] [condition]

### API / Service Availability
- [ ] [condition]
```

Flag external dependencies with `⚠️ external dependency`.

---

**Section 5: Open Questions for Data Team**

List anything that cannot be determined from the spec alone:

```
Q1: [question about a specific value or constraint]
    Blocks: [which test records cannot be built until this is answered]

Q2: [question]
    Blocks: [records]
```

---

**Section 6: Named Records (if applicable)**

Only generate if the spec involves creating persistent records (accounts, profiles, variables, etc.).

```
Naming convention: [e.g. tc_<field>_<number>]

| Record Name | Key Field Values | Purpose |
|---|---|---|
| [name] | [field=value, field=value] | [which tests use this record] |
```
