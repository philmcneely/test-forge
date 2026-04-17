#!/usr/bin/env bash
# TC-F: Output filename derivation tests
# Verifies OUTPUT_FILE is correctly derived from KEY + active flags.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-F: Output Filename Tests ==="
echo ""

check_filename() {
  local label="$1" expected="$2"; shift 2
  parse_flags "$@"
  assert_eq "$label" "$expected" "$OUTPUT_FILE"
}

# ── Basic flag combinations ────────────────────────────────────────────────
check_filename "TC-F01 no flags"                           "PROJ-123_tests.md"                           "PROJ-123"
check_filename "TC-F02 --no-gherkin"                       "PROJ-123_tests_no_gherkin.md"                "PROJ-123" "--no-gherkin"
check_filename "TC-F03 --blackbox"                         "PROJ-123_tests_blackbox.md"                  "PROJ-123" "--blackbox"
check_filename "TC-F04 --blackbox --no-gherkin"            "PROJ-123_tests_blackbox_no_gherkin.md"       "PROJ-123" "--blackbox" "--no-gherkin"
check_filename "TC-F05 --neg-only"                         "PROJ-123_tests_neg.md"                       "PROJ-123" "--neg-only"
check_filename "TC-F06 --neg-only --no-gherkin"            "PROJ-123_tests_neg_no_gherkin.md"            "PROJ-123" "--neg-only" "--no-gherkin"
check_filename "TC-F07 --neg-only --blackbox"              "PROJ-123_tests_blackbox_neg.md"              "PROJ-123" "--neg-only" "--blackbox"
check_filename "TC-F08 --neg-only --blackbox --no-gherkin" "PROJ-123_tests_blackbox_neg_no_gherkin.md"   "PROJ-123" "--neg-only" "--blackbox" "--no-gherkin"

# ── --no-clarify exception rules ──────────────────────────────────────────
check_filename "TC-F09 --no-clarify only → no suffix"      "PROJ-123_tests.md"                           "PROJ-123" "--no-clarify"
check_filename "TC-F10 --no-clarify --no-gherkin"          "PROJ-123_tests_no_gherkin.md"                "PROJ-123" "--no-clarify" "--no-gherkin"
check_filename "TC-F11 --no-clarify --blackbox"            "PROJ-123_tests_blackbox.md"                  "PROJ-123" "--no-clarify" "--blackbox"

# ── Suffix ordering ────────────────────────────────────────────────────────
# TC-F12: order must be blackbox → neg → no_gherkin
parse_flags "PROJ-123" "--neg-only" "--blackbox" "--no-gherkin"
assert_eq "TC-F12 suffix order: blackbox < neg < no_gherkin" \
  "PROJ-123_tests_blackbox_neg_no_gherkin.md" "$OUTPUT_FILE"

# ── Different KEY values ───────────────────────────────────────────────────
check_filename "TC-F13a different KEY ABC-456"             "ABC-456_tests.md"                            "ABC-456"
check_filename "TC-F13b KEY with longer project prefix"    "MYPROJ-9999_tests_blackbox.md"               "MYPROJ-9999" "--blackbox"

# ── --output-dir sets OUTPUT_DIR, does not affect OUTPUT_FILE name ─────────
parse_flags "PROJ-123" "--output-dir" "custom/path"
assert_eq "TC-F14a OUTPUT_DIR set"         "custom/path"       "$OUTPUT_DIR"
assert_eq "TC-F14b OUTPUT_FILE unaffected" "PROJ-123_tests.md" "$OUTPUT_FILE"

parse_flags "PROJ-123" "--output-dir" "reports/qe" "--neg-only"
assert_eq "TC-F14c OUTPUT_DIR with --neg-only"   "reports/qe"             "$OUTPUT_DIR"
assert_eq "TC-F14d OUTPUT_FILE still has suffix" "PROJ-123_tests_neg.md"  "$OUTPUT_FILE"

# ── --neg-only implies --no-clarify — filename uses neg suffix not blank ───
check_filename "TC-F15 --neg-only implies no-clarify (neg suffix)" "PROJ-123_tests_neg.md" "PROJ-123" "--neg-only"

# ── Redundant flags don't break anything ──────────────────────────────────
check_filename "TC-F16 --neg-only --no-clarify (redundant) same as --neg-only" \
  "PROJ-123_tests_neg.md" "PROJ-123" "--neg-only" "--no-clarify"

# ── --create and --follow do not affect filename ───────────────────────────
check_filename "TC-F17 --create does not affect filename" "PROJ-123_tests.md"            "PROJ-123" "--create"
check_filename "TC-F18 --follow does not affect filename" "PROJ-123_tests.md"            "PROJ-123" "--follow"
check_filename "TC-F19 --create --follow --blackbox"      "PROJ-123_tests_blackbox.md"   "PROJ-123" "--create" "--follow" "--blackbox"

echo ""
print_summary
