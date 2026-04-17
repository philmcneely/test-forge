#!/usr/bin/env bash
# TC-R: Router section-file loading tests
# Verifies the correct set of section files is loaded for each flag combination.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-R: Router Section Loading Tests ==="
echo ""

# ── TC-R01: Default invocation ─────────────────────────────────────────────
parse_flags "PROJ-123"; derive_sections
assert_contains     "TC-R01 always.md loaded"           "sections/always.md"         "${SECTIONS_TO_LOAD[*]}"
assert_contains     "TC-R01 fetch.md loaded"            "sections/fetch.md"           "${SECTIONS_TO_LOAD[*]}"
assert_contains     "TC-R01 format.md loaded"           "sections/format.md"          "${SECTIONS_TO_LOAD[*]}"
assert_contains     "TC-R01 sections-neg.md loaded"     "sections/sections-neg.md"    "${SECTIONS_TO_LOAD[*]}"
assert_contains     "TC-R01 sections-meta.md loaded"    "sections/sections-meta.md"   "${SECTIONS_TO_LOAD[*]}"
assert_contains     "TC-R01 write.md loaded"            "sections/write.md"           "${SECTIONS_TO_LOAD[*]}"
assert_contains     "TC-R01 sections-happy.md loaded"   "sections/sections-happy.md"  "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R01 fetch-follow NOT loaded"    "sections/fetch-follow.md"    "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R01 total 7 sections"           "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R02: --follow ───────────────────────────────────────────────────────
parse_flags "PROJ-123" "--follow"; derive_sections
assert_contains     "TC-R02 fetch-follow.md loaded"     "sections/fetch-follow.md"    "${SECTIONS_TO_LOAD[*]}"
assert_contains     "TC-R02 sections-happy.md loaded"   "sections/sections-happy.md"  "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R02 total 8 sections"           "8" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R03: --neg-only ─────────────────────────────────────────────────────
parse_flags "PROJ-123" "--neg-only"; derive_sections
assert_not_contains "TC-R03 sections-happy NOT loaded"  "sections/sections-happy.md"  "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R03 fetch-follow NOT loaded"    "sections/fetch-follow.md"    "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R03 total 6 sections"           "6" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R04: --neg-only --follow ────────────────────────────────────────────
parse_flags "PROJ-123" "--neg-only" "--follow"; derive_sections
assert_contains     "TC-R04 fetch-follow.md loaded"     "sections/fetch-follow.md"    "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R04 sections-happy NOT loaded"  "sections/sections-happy.md"  "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R04 total 7 sections"           "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R05: --no-gherkin (format change only — no routing change) ──────────
parse_flags "PROJ-123" "--no-gherkin"; derive_sections
assert_contains     "TC-R05 sections-happy.md loaded"   "sections/sections-happy.md"  "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R05 fetch-follow NOT loaded"    "sections/fetch-follow.md"    "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R05 total 7 sections"           "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R06: --blackbox (language change only — no routing change) ──────────
parse_flags "PROJ-123" "--blackbox"; derive_sections
assert_eq           "TC-R06 total 7 sections"           "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R07: --no-clarify (generation skip only — no routing change) ────────
parse_flags "PROJ-123" "--no-clarify"; derive_sections
assert_eq           "TC-R07 total 7 sections"           "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R08: --create (write behaviour change — no routing change) ──────────
parse_flags "PROJ-123" "--create"; derive_sections
assert_eq           "TC-R08 total 7 sections"           "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R09: Always-loaded set is invariant across all flag combos ──────────
echo ""
echo "  TC-R09: always-loaded set invariant check"
always_files=("sections/always.md" "sections/fetch.md" "sections/format.md"
              "sections/sections-neg.md" "sections/sections-meta.md" "sections/write.md")

while IFS= read -r test_args_raw; do
  read -ra test_args <<< "$test_args_raw"
  parse_flags "${test_args[@]}"; derive_sections
  for f in "${always_files[@]}"; do
    assert_contains "TC-R09 $f in [${test_args[*]}]" "$f" "${SECTIONS_TO_LOAD[*]}"
  done
done <<'ARGS'
PROJ-1
PROJ-1 --create
PROJ-1 --follow
PROJ-1 --neg-only
PROJ-1 --blackbox --neg-only --follow --create --no-gherkin
ARGS

# ── TC-R10: Full combo --follow --neg-only --blackbox --no-gherkin --create ─
parse_flags "PROJ-123" "--follow" "--neg-only" "--blackbox" "--no-gherkin" "--create"; derive_sections
assert_contains     "TC-R10 fetch-follow.md loaded"     "sections/fetch-follow.md"    "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R10 sections-happy NOT loaded"  "sections/sections-happy.md"  "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R10 total 7 sections"           "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-C01: --blackbox --follow ────────────────────────────────────────────
parse_flags "PROJ-123" "--blackbox" "--follow"; derive_sections
assert_eq "TC-C01 BLACKBOX=true" "true" "$BLACKBOX"
assert_eq "TC-C01 FOLLOW=true"   "true" "$FOLLOW"
assert_eq "TC-C01 total 8"       "8"    "${#SECTIONS_TO_LOAD[@]}"

# ── TC-C02: --blackbox --neg-only ─────────────────────────────────────────
parse_flags "PROJ-123" "--blackbox" "--neg-only"; derive_sections
assert_eq "TC-C02 BLACKBOX=true"    "true" "$BLACKBOX"
assert_eq "TC-C02 NEG_ONLY=true"    "true" "$NEG_ONLY"
assert_eq "TC-C02 NO_CLARIFY=true"  "true" "$NO_CLARIFY"
assert_eq "TC-C02 total 6"          "6"    "${#SECTIONS_TO_LOAD[@]}"

# ── TC-C03: --create --no-gherkin --blackbox ──────────────────────────────
parse_flags "PROJ-123" "--create" "--no-gherkin" "--blackbox"; derive_sections
assert_eq "TC-C03 CREATE=true"   "true"  "$CREATE"
assert_eq "TC-C03 GHERKIN=false" "false" "$GHERKIN"
assert_eq "TC-C03 BLACKBOX=true" "true"  "$BLACKBOX"
assert_eq "TC-C03 total 7"       "7"     "${#SECTIONS_TO_LOAD[@]}"

# ── TC-C04: --follow --no-gherkin ─────────────────────────────────────────
parse_flags "PROJ-123" "--follow" "--no-gherkin"; derive_sections
assert_eq "TC-C04 GHERKIN=false" "false" "$GHERKIN"
assert_eq "TC-C04 FOLLOW=true"   "true"  "$FOLLOW"
assert_eq "TC-C04 total 8"       "8"     "${#SECTIONS_TO_LOAD[@]}"

# ── TC-C05: All flags ─────────────────────────────────────────────────────
parse_flags "PROJ-123" "--neg-only" "--blackbox" "--follow" "--create" "--no-gherkin"; derive_sections
assert_contains     "TC-C05 fetch-follow loaded"        "sections/fetch-follow.md"    "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-C05 sections-happy NOT loaded"  "sections/sections-happy.md"  "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-C05 total 7"                    "7" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-C06: Everything except --neg-only and --follow ─────────────────────
parse_flags "PROJ-123" "--create" "--no-gherkin" "--blackbox" "--no-clarify"; derive_sections
assert_contains     "TC-C06 sections-happy present"     "sections/sections-happy.md"  "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-C06 fetch-follow absent"        "sections/fetch-follow.md"    "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-C06 total 7"                    "7" "${#SECTIONS_TO_LOAD[@]}"

echo ""
print_summary
