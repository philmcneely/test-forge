# Changelog

## 2026-04-01

### Fix: jira-clarify and jira-test-gen — Acceptance Criteria custom field now fetched

**Root cause discovered via:** a real Jira ticket with fully-written Gherkin ACs.

Running `/jira-clarify` on the ticket revealed that the skill was generating questions
asking "where are the ACs?" when 6 fully-written Gherkin ACs already existed on the ticket.
They were stored in `customfield_10063` (the "Acceptance Criteria" textarea field) and were
never being fetched by the skills -- only the `description` field was included in the API call.

**Fix:** Added `customfield_10063` (Acceptance Criteria) and `customfield_10144` (Acceptance Test)
to the `fields=` parameter in Step 2 of `jira-clarify` and `jira-test-gen`. Both fields are
fetched silently; null/absent values are ignored; non-null values are included as AC context.
