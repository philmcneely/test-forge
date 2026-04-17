#!/usr/bin/env bash
# tests/confluence-breakdown/test_router.sh
# Tests router section loading and flag parsing for confluence-breakdown.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/confluence-breakdown" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-R: Router Tests (confluence-breakdown) ==="
echo ""

URL="https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec"

# ── TC-R01: default — 4 sections always loaded ────────────────────
parse_flags "$URL"
derive_sections
assert_contains "TC-R01 always.md"  "sections/always.md"  "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 fetch.md"   "sections/fetch.md"   "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 analyze.md" "sections/analyze.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 write.md"   "sections/write.md"   "${SECTIONS_TO_LOAD[*]}"
assert_eq       "TC-R01 total 4"    "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R02: --create does not change section count ────────────────
parse_flags "$URL" --create
derive_sections
assert_eq "TC-R02 still 4 with --create" "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R03: --parent does not change section count ────────────────
parse_flags "$URL" --parent PROJ-10
derive_sections
assert_eq "TC-R03 still 4 with --parent" "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R04: --create --parent combined still 4 ───────────────────
parse_flags "$URL" --create --parent PROJ-10
derive_sections
assert_eq "TC-R04 still 4 with --create --parent" "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R05: always-loaded invariant across all combos ────────────
echo ""
echo "  TC-R05: always-loaded invariant"
ALWAYS_SET=("sections/always.md" "sections/fetch.md" "sections/analyze.md" "sections/write.md")
for combo in \
  "$URL" \
  "$URL --create" \
  "$URL --parent PROJ-10" \
  "$URL --create --parent PROJ-10"
do
  parse_flags $combo
  derive_sections
  for sec in "${ALWAYS_SET[@]}"; do
    assert_contains "TC-R05 $sec in [$combo]" "$sec" "${SECTIONS_TO_LOAD[*]}"
  done
done

# ── TC-C01: flag defaults ─────────────────────────────────────────
parse_flags "$URL"
assert_eq "TC-C01a CREATE default=false"     "false" "$CREATE"
assert_eq "TC-C01b PARENT_KEY default empty" ""      "$PARENT_KEY"

# ── TC-C02: --create sets CREATE=true ────────────────────────────
parse_flags "$URL" --create
assert_eq "TC-C02 CREATE=true" "true" "$CREATE"

# ── TC-C03: --parent sets PARENT_KEY ─────────────────────────────
parse_flags "$URL" --parent PROJ-42
assert_eq "TC-C03 PARENT_KEY=PROJ-42" "PROJ-42" "$PARENT_KEY"

# ── TC-C04: --output-dir sets OUTPUT_DIR ─────────────────────────
parse_flags "$URL" --output-dir /tmp/breakdown
assert_eq "TC-C04 OUTPUT_DIR" "/tmp/breakdown" "$OUTPUT_DIR"

print_summary
