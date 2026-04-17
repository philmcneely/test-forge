#!/usr/bin/env bash
# tests/confluence-test-gen/test_router.sh
# Tests router section loading logic for confluence-test-gen.
# Usage: bash tests/confluence-test-gen/test_router.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/confluence-test-gen" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-R: Router Section Loading Tests (confluence-test-gen) ==="
echo ""

# ── TC-R01: default (no flags) ─────────────────────────────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec"
derive_sections
assert_contains "TC-R01 always.md loaded"        "sections/always.md"       "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 fetch.md loaded"          "sections/fetch.md"        "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 format.md loaded"         "sections/format.md"       "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 sections-neg.md loaded"   "sections/sections-neg.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 sections-meta.md loaded"  "sections/sections-meta.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 write.md loaded"          "sections/write.md"        "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 sections-happy.md loaded" "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 testdata.md loaded"       "sections/testdata.md"     "${SECTIONS_TO_LOAD[*]}"
assert_eq       "TC-R01 total 8 sections"         "8"  "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R02: --neg-only skips sections-happy.md ─────────────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --neg-only
derive_sections
assert_not_contains "TC-R02 sections-happy NOT loaded" "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains     "TC-R02 testdata.md still loaded"  "sections/testdata.md"       "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R02 total 7 sections"          "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R03: --no-testdata skips testdata.md ────────────────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --no-testdata
derive_sections
assert_contains     "TC-R03 sections-happy loaded"     "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R03 testdata NOT loaded"       "sections/testdata.md"       "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R03 total 7 sections"          "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R04: --neg-only --no-testdata skips both ────────────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --neg-only --no-testdata
derive_sections
assert_not_contains "TC-R04 sections-happy NOT loaded" "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R04 testdata NOT loaded"       "sections/testdata.md"       "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R04 total 6 sections"          "6" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R05: --testdata-only still loads testdata.md ───────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --testdata-only
derive_sections
assert_contains "TC-R05 testdata.md loaded" "sections/testdata.md" "${SECTIONS_TO_LOAD[*]}"
# testdata-only does NOT skip sections-happy at router level (content guarded in format.md)
assert_eq       "TC-R05 total 8 sections"   "8" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R06: --blackbox does not change section set ─────────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --blackbox
derive_sections
assert_eq "TC-R06 total 8 sections" "8" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R07: --no-gherkin does not change section set ───────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --no-gherkin
derive_sections
assert_eq "TC-R07 total 8 sections" "8" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R08: --create does not change section set ───────────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --create
derive_sections
assert_eq "TC-R08 total 8 sections" "8" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R09: always-loaded set invariant ───────────────────────────
echo ""
echo "  TC-R09: always-loaded set invariant check"
ALWAYS_SET=("sections/always.md" "sections/fetch.md" "sections/format.md" "sections/sections-neg.md" "sections/sections-meta.md" "sections/write.md")
for combo in \
  "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" \
  "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec --create" \
  "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec --neg-only" \
  "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec --no-testdata" \
  "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec --blackbox --neg-only --no-testdata --create --no-gherkin"
do
  parse_flags $combo
  derive_sections
  for sec in "${ALWAYS_SET[@]}"; do
    assert_contains "TC-R09 $sec in [$combo]" "$sec" "${SECTIONS_TO_LOAD[*]}"
  done
done

# ── TC-C01: --blackbox + --include-children flag states ───────────
echo ""
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --blackbox --include-children
derive_sections
assert_eq "TC-C01 BLACKBOX=true"          "true"  "$BLACKBOX"
assert_eq "TC-C01 INCLUDE_CHILDREN=true"  "true"  "$INCLUDE_CHILDREN"
assert_eq "TC-C01 total 8"                "8"     "${#SECTIONS_TO_LOAD[@]}"

# ── TC-C02: --neg-only implies NO_CLARIFY and testdata still loads ─
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --neg-only
derive_sections
assert_eq "TC-C02 NEG_ONLY=true"    "true" "$NEG_ONLY"
assert_eq "TC-C02 NO_CLARIFY=true"  "true" "$NO_CLARIFY"
assert_eq "TC-C02 total 7"          "7"    "${#SECTIONS_TO_LOAD[@]}"

# ── TC-C03: --testdata-only implies NO_CLARIFY ────────────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --testdata-only
derive_sections
assert_eq "TC-C03 TESTDATA_ONLY=true" "true" "$TESTDATA_ONLY"
assert_eq "TC-C03 NO_CLARIFY=true"    "true" "$NO_CLARIFY"

# ── TC-C04: --no-clarify alone does not affect section set ────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --no-clarify
derive_sections
assert_eq "TC-C04 NO_CLARIFY=true"  "true" "$NO_CLARIFY"
assert_eq "TC-C04 NEG_ONLY=false"   "false" "$NEG_ONLY"
assert_eq "TC-C04 total 8"          "8"    "${#SECTIONS_TO_LOAD[@]}"

# ── TC-C05: CREATE + GHERKIN flags ───────────────────────────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec" --create --no-gherkin --blackbox
derive_sections
assert_eq "TC-C05 CREATE=true"    "true"  "$CREATE"
assert_eq "TC-C05 GHERKIN=false"  "false" "$GHERKIN"
assert_eq "TC-C05 BLACKBOX=true"  "true"  "$BLACKBOX"
assert_eq "TC-C05 total 8"        "8"     "${#SECTIONS_TO_LOAD[@]}"

print_summary
