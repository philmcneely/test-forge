#!/usr/bin/env bash
# tests/confluence-test-gen/test_filenames.sh
# Tests output filename derivation for confluence-test-gen.
# Usage: bash tests/confluence-test-gen/test_filenames.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-F: Output Filename Tests (confluence-test-gen) ==="
echo ""

URL="https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec"

# ── TC-F01: no flags → base filename ──────────────────────────────
parse_flags "$URL"
assert_eq "TC-F01 no flags" "confluence-test_page_tests.md" "$OUTPUT_FILE"

# ── TC-F02: --no-gherkin ──────────────────────────────────────────
parse_flags "$URL" --no-gherkin
assert_eq "TC-F02 --no-gherkin" "confluence-test_page_tests_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F03: --blackbox ────────────────────────────────────────────
parse_flags "$URL" --blackbox
assert_eq "TC-F03 --blackbox" "confluence-test_page_tests_blackbox.md" "$OUTPUT_FILE"

# ── TC-F04: --blackbox --no-gherkin ──────────────────────────────
parse_flags "$URL" --blackbox --no-gherkin
assert_eq "TC-F04 --blackbox --no-gherkin" "confluence-test_page_tests_blackbox_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F05: --neg-only ────────────────────────────────────────────
parse_flags "$URL" --neg-only
assert_eq "TC-F05 --neg-only" "confluence-test_page_tests_neg.md" "$OUTPUT_FILE"

# ── TC-F06: --neg-only --no-gherkin ──────────────────────────────
parse_flags "$URL" --neg-only --no-gherkin
assert_eq "TC-F06 --neg-only --no-gherkin" "confluence-test_page_tests_neg_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F07: --neg-only --blackbox ────────────────────────────────
parse_flags "$URL" --neg-only --blackbox
assert_eq "TC-F07 --neg-only --blackbox" "confluence-test_page_tests_blackbox_neg.md" "$OUTPUT_FILE"

# ── TC-F08: --neg-only --blackbox --no-gherkin ───────────────────
parse_flags "$URL" --neg-only --blackbox --no-gherkin
assert_eq "TC-F08 --neg-only --blackbox --no-gherkin" "confluence-test_page_tests_blackbox_neg_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F09: --no-clarify only → no suffix ────────────────────────
parse_flags "$URL" --no-clarify
assert_eq "TC-F09 --no-clarify only → no suffix" "confluence-test_page_tests.md" "$OUTPUT_FILE"

# ── TC-F10: --no-clarify --no-gherkin → has suffix ───────────────
parse_flags "$URL" --no-clarify --no-gherkin
assert_eq "TC-F10 --no-clarify --no-gherkin" "confluence-test_page_tests_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F11: --no-clarify --blackbox → has suffix ─────────────────
parse_flags "$URL" --no-clarify --blackbox
assert_eq "TC-F11 --no-clarify --blackbox" "confluence-test_page_tests_blackbox.md" "$OUTPUT_FILE"

# ── TC-F12: suffix order blackbox < neg < no_gherkin ─────────────
parse_flags "$URL" --no-gherkin --neg-only --blackbox
assert_eq "TC-F12 suffix order" "confluence-test_page_tests_blackbox_neg_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F13: testdata file is always the same ─────────────────────
parse_flags "$URL" --neg-only --blackbox
assert_eq "TC-F13 testdata file" "confluence-test_page_testdata.md" "$TESTDATA_FILE"

parse_flags "$URL" --no-testdata
assert_eq "TC-F13b testdata file still set (guarded in section)" "confluence-test_page_testdata.md" "$TESTDATA_FILE"

# ── TC-F14: --create does not affect filename ────────────────────
parse_flags "$URL" --create
assert_eq "TC-F14 --create no effect" "confluence-test_page_tests.md" "$OUTPUT_FILE"

# ── TC-F15: --include-children does not affect filename ──────────
parse_flags "$URL" --include-children
assert_eq "TC-F15 --include-children no effect" "confluence-test_page_tests.md" "$OUTPUT_FILE"

# ── TC-F16: --testdata-only implies --no-clarify → no suffix ─────
parse_flags "$URL" --testdata-only
assert_eq "TC-F16a TESTDATA_ONLY=true"  "true" "$TESTDATA_ONLY"
assert_eq "TC-F16b NO_CLARIFY=true"     "true" "$NO_CLARIFY"
assert_eq "TC-F16c no suffix"           "confluence-test_page_tests.md" "$OUTPUT_FILE"

# ── TC-F17: --neg-only implies NO_CLARIFY ────────────────────────
parse_flags "$URL" --neg-only
assert_eq "TC-F17a NEG_ONLY=true"   "true" "$NEG_ONLY"
assert_eq "TC-F17b NO_CLARIFY=true" "true" "$NO_CLARIFY"

print_summary
