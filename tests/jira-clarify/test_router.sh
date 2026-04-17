#!/usr/bin/env bash
# tests/jira-clarify/test_router.sh
# Tests router section loading and flag parsing for jira-clarify.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/jira-clarify" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-R: Router Tests (jira-clarify) ==="
echo ""

KEY="PROJ-123"

# ── TC-R01: default — 4 sections always loaded ────────────────────
parse_flags "$KEY"
derive_sections
assert_contains "TC-R01 always.md"   "sections/always.md"   "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 fetch.md"    "sections/fetch.md"    "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 generate.md" "sections/generate.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 write.md"    "sections/write.md"    "${SECTIONS_TO_LOAD[*]}"
assert_eq       "TC-R01 total 4"     "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R02: --create does not change section count ────────────────
parse_flags "$KEY" --create
derive_sections
assert_eq "TC-R02 still 4 with --create" "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R03: --output-dir does not change section count ───────────
parse_flags "$KEY" --output-dir /tmp
derive_sections
assert_eq "TC-R03 still 4 with --output-dir" "4" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R04: always-loaded invariant ──────────────────────────────
echo ""
echo "  TC-R04: always-loaded invariant"
ALWAYS_SET=("sections/always.md" "sections/fetch.md" "sections/generate.md" "sections/write.md")
for combo in "$KEY" "$KEY --create" "$KEY --output-dir /tmp" "$KEY --create --output-dir /tmp"; do
  parse_flags $combo
  derive_sections
  for sec in "${ALWAYS_SET[@]}"; do
    assert_contains "TC-R04 $sec in [$combo]" "$sec" "${SECTIONS_TO_LOAD[*]}"
  done
done

# ── TC-C01: flag defaults ─────────────────────────────────────────
parse_flags "$KEY"
assert_eq "TC-C01a JIRA_KEY"          "PROJ-123" "$JIRA_KEY"
assert_eq "TC-C01b PROJECT_KEY"       "PROJ"     "$PROJECT_KEY"
assert_eq "TC-C01c CREATE default"    "false"    "$CREATE"
assert_eq "TC-C01d OUTPUT_DIR default" "output"  "$OUTPUT_DIR"

# ── TC-C02: different key formats ─────────────────────────────────
parse_flags "ABC-456"
assert_eq "TC-C02a JIRA_KEY=ABC-456"  "ABC-456" "$JIRA_KEY"
assert_eq "TC-C02b PROJECT_KEY=ABC"   "ABC"     "$PROJECT_KEY"

parse_flags "LONGKEY-1001"
assert_eq "TC-C02c PROJECT_KEY=LONGKEY" "LONGKEY" "$PROJECT_KEY"

# ── TC-C03: --create sets CREATE=true ────────────────────────────
parse_flags "$KEY" --create
assert_eq "TC-C03 CREATE=true" "true" "$CREATE"

# ── TC-C04: OUTPUT_FILE is <KEY>_clarify.md ───────────────────────
parse_flags "$KEY"
assert_eq "TC-C04 OUTPUT_FILE" "PROJ-123_clarify.md" "$OUTPUT_FILE"

parse_flags "ABC-789"
assert_eq "TC-C04b OUTPUT_FILE ABC-789" "ABC-789_clarify.md" "$OUTPUT_FILE"

print_summary
