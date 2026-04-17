#!/usr/bin/env bash
# tests/confluence-clarify/test_router.sh
# Tests router section loading and flag parsing for confluence-clarify.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/confluence-clarify" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-R: Router Tests (confluence-clarify) ==="
echo ""

URL="https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec"

# ── TC-R01: default — 4 sections always loaded ────────────────────
parse_flags "$URL"
derive_sections
assert_contains "TC-R01 always.md"   "sections/always.md"   "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 fetch.md"    "sections/fetch.md"    "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 generate.md" "sections/generate.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 write.md"    "sections/write.md"    "${SECTIONS_TO_LOAD[*]}"
assert_eq       "TC-R01 total 4"     "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R02: --create does not change section count ────────────────
parse_flags "$URL" --create
derive_sections
assert_eq "TC-R02 still 4 with --create" "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R03: --output-dir does not change section count ───────────
parse_flags "$URL" --output-dir /tmp
derive_sections
assert_eq "TC-R03 still 4 with --output-dir" "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R04: always-loaded invariant across all combos ────────────
echo ""
echo "  TC-R04: always-loaded invariant"
ALWAYS_SET=("sections/always.md" "sections/fetch.md" "sections/generate.md" "sections/write.md")
for combo in \
  "$URL" \
  "$URL --create" \
  "$URL --output-dir /tmp"
do
  parse_flags $combo
  derive_sections
  for sec in "${ALWAYS_SET[@]}"; do
    assert_contains "TC-R04 $sec in [$combo]" "$sec" "${SECTIONS_TO_LOAD[*]}"
  done
done

# ── TC-C01: flag defaults ─────────────────────────────────────────
parse_flags "$URL"
assert_eq "TC-C01a CREATE default=false" "false"  "$CREATE"
assert_eq "TC-C01b OUTPUT_DIR default"   "output" "$OUTPUT_DIR"

# ── TC-C02: --create sets CREATE=true ────────────────────────────
parse_flags "$URL" --create
assert_eq "TC-C02 CREATE=true" "true" "$CREATE"

# ── TC-C03: --output-dir sets OUTPUT_DIR ─────────────────────────
parse_flags "$URL" --output-dir /custom/path
assert_eq "TC-C03 OUTPUT_DIR" "/custom/path" "$OUTPUT_DIR"

# ── TC-C04: OUTPUT_FILE ends with _clarify.md ────────────────────
parse_flags "$URL"
assert_eq "TC-C04 OUTPUT_FILE suffix" "_clarify.md" "${OUTPUT_FILE: -11}"

print_summary
