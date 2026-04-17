#!/usr/bin/env bash
# tests/mr-review/test_router.sh
# Tests router section loading logic for mr-review.
# Usage: bash tests/mr-review/test_router.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-R: Router Section Loading Tests (mr-review) ==="
echo ""

GITLAB_URL="https://gitlab.company.net/group/repo/-/merge_requests/622"
GITHUB_URL="https://github.com/org/repo/pull/123"

# ── TC-R01: default (no flags) — all 5 sections always loaded ────
parse_flags "$GITLAB_URL"
derive_sections
assert_contains "TC-R01 always.md loaded"   "sections/always.md"   "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 fetch.md loaded"    "sections/fetch.md"    "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 format.md loaded"   "sections/format.md"   "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 sections.md loaded" "sections/sections.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 write.md loaded"    "sections/write.md"    "${SECTIONS_TO_LOAD[*]}"
assert_eq       "TC-R01 total 5 sections"   "5" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R02: --blackbox does not change section count ─────────────
parse_flags "$GITLAB_URL" --blackbox
derive_sections
assert_eq "TC-R02 total 5 sections" "5" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R03: --no-gherkin does not change section count ───────────
parse_flags "$GITLAB_URL" --no-gherkin
derive_sections
assert_eq "TC-R03 total 5 sections" "5" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R04: --create does not change section count ───────────────
parse_flags "$GITLAB_URL" --create
derive_sections
assert_eq "TC-R04 total 5 sections" "5" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R05: --jira does not change section count ─────────────────
parse_flags "$GITLAB_URL" --jira PROJ-123
derive_sections
assert_eq "TC-R05 total 5 sections" "5" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R06: --confluence does not change section count ───────────
parse_flags "$GITLAB_URL" --confluence "https://example.atlassian.net/wiki/spaces/SP/pages/123"
derive_sections
assert_eq "TC-R06 total 5 sections" "5" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R07: all flags combined still 5 sections ──────────────────
parse_flags "$GITLAB_URL" --jira PROJ-123 --confluence "https://example.atlassian.net/wiki/spaces/SP/pages/123" --create --no-gherkin --blackbox
derive_sections
assert_eq "TC-R07 total 5 sections" "5" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R08: GitHub URL still 5 sections ──────────────────────────
parse_flags "$GITHUB_URL"
derive_sections
assert_eq "TC-R08 total 5 sections" "5" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R09: always-loaded set invariant ───────────────────────────
echo ""
echo "  TC-R09: always-loaded set invariant check"
ALWAYS_SET=("sections/always.md" "sections/fetch.md" "sections/format.md" "sections/sections.md" "sections/write.md")
for combo in \
  "$GITLAB_URL" \
  "$GITLAB_URL --create" \
  "$GITLAB_URL --blackbox" \
  "$GITLAB_URL --no-gherkin" \
  "$GITLAB_URL --jira PROJ-123" \
  "$GITLAB_URL --blackbox --no-gherkin --create --jira PROJ-123"
do
  parse_flags $combo
  derive_sections
  for sec in "${ALWAYS_SET[@]}"; do
    assert_contains "TC-R09 $sec in [$combo]" "$sec" "${SECTIONS_TO_LOAD[*]}"
  done
done

# ── TC-C01: platform detection — GitLab ───────────────────────────
parse_flags "$GITLAB_URL"
assert_eq "TC-C01 GITLAB=true"  "true"  "$GITLAB"
assert_eq "TC-C01 GITHUB=false" "false" "$GITHUB"
assert_eq "TC-C01 MR_ID=622"   "622"   "$MR_ID"

# ── TC-C02: platform detection — GitHub ───────────────────────────
parse_flags "$GITHUB_URL"
assert_eq "TC-C02 GITLAB=false" "false" "$GITLAB"
assert_eq "TC-C02 GITHUB=true"  "true"  "$GITHUB"
assert_eq "TC-C02 MR_ID=123"   "123"   "$MR_ID"

# ── TC-C03: --jira and --confluence flags ─────────────────────────
parse_flags "$GITLAB_URL" --jira ABC-456 --confluence "https://example.atlassian.net/wiki/spaces/SP/pages/789"
assert_eq "TC-C03 JIRA_KEY=ABC-456"        "ABC-456"    "$JIRA_KEY"
assert_eq "TC-C03 CONFLUENCE_URL set"      "https://example.atlassian.net/wiki/spaces/SP/pages/789" "$CONFLUENCE_URL"

# ── TC-C04: CREATE and GHERKIN defaults ──────────────────────────
parse_flags "$GITLAB_URL"
assert_eq "TC-C04a CREATE default=false" "false" "$CREATE"
assert_eq "TC-C04b GHERKIN default=true" "true"  "$GHERKIN"

parse_flags "$GITLAB_URL" --create --no-gherkin
assert_eq "TC-C04c CREATE=true"   "true"  "$CREATE"
assert_eq "TC-C04d GHERKIN=false" "false" "$GHERKIN"

print_summary
