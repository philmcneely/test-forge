#!/usr/bin/env bash
# tests/mr-review/test_filenames.sh
# Tests output filename derivation for mr-review.
# Usage: bash tests/mr-review/test_filenames.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-F: Output Filename Tests (mr-review) ==="
echo ""

GL="https://gitlab.company.net/group/repo/-/merge_requests/622"
GH="https://github.com/org/repo/pull/123"

# ── TC-F01: no flags → base filename ──────────────────────────────
parse_flags "$GL"
assert_eq "TC-F01 no flags" "mr-622_review.md" "$OUTPUT_FILE"

# ── TC-F02: --no-gherkin ──────────────────────────────────────────
parse_flags "$GL" --no-gherkin
assert_eq "TC-F02 --no-gherkin" "mr-622_review_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F03: --blackbox ────────────────────────────────────────────
parse_flags "$GL" --blackbox
assert_eq "TC-F03 --blackbox" "mr-622_review_blackbox.md" "$OUTPUT_FILE"

# ── TC-F04: --blackbox --no-gherkin ──────────────────────────────
parse_flags "$GL" --blackbox --no-gherkin
assert_eq "TC-F04 --blackbox --no-gherkin" "mr-622_review_blackbox_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F05: suffix order blackbox < no_gherkin ───────────────────
parse_flags "$GL" --no-gherkin --blackbox
assert_eq "TC-F05 suffix order" "mr-622_review_blackbox_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F06: --create does not affect filename ────────────────────
parse_flags "$GL" --create
assert_eq "TC-F06 --create no effect" "mr-622_review.md" "$OUTPUT_FILE"

# ── TC-F07: --jira does not affect filename ───────────────────────
parse_flags "$GL" --jira PROJ-123
assert_eq "TC-F07 --jira no effect" "mr-622_review.md" "$OUTPUT_FILE"

# ── TC-F08: --confluence does not affect filename ────────────────
parse_flags "$GL" --confluence "https://example.atlassian.net/wiki/spaces/SP/pages/789"
assert_eq "TC-F08 --confluence no effect" "mr-622_review.md" "$OUTPUT_FILE"

# ── TC-F09: GitHub URL extracts correct MR_ID ────────────────────
parse_flags "$GH"
assert_eq "TC-F09 GitHub MR_ID" "mr-123_review.md" "$OUTPUT_FILE"

# ── TC-F10: GitHub --blackbox --no-gherkin ───────────────────────
parse_flags "$GH" --blackbox --no-gherkin
assert_eq "TC-F10 GitHub --blackbox --no-gherkin" "mr-123_review_blackbox_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F11: different MR numbers ─────────────────────────────────
parse_flags "https://gitlab.company.net/group/repo/-/merge_requests/1001"
assert_eq "TC-F11a MR_ID 1001" "mr-1001_review.md" "$OUTPUT_FILE"

parse_flags "https://github.com/org/repo/pull/42"
assert_eq "TC-F11b MR_ID 42" "mr-42_review.md" "$OUTPUT_FILE"

# ── TC-F12: --output-dir does not change OUTPUT_FILE base ────────
parse_flags "$GL" --output-dir "/tmp/reviews"
assert_eq "TC-F12a OUTPUT_DIR set"    "/tmp/reviews"    "$OUTPUT_DIR"
assert_eq "TC-F12b OUTPUT_FILE base"  "mr-622_review.md" "$OUTPUT_FILE"

# ── TC-F13: all non-filename flags combined ───────────────────────
parse_flags "$GL" --create --jira PROJ-123 --confluence "https://example.atlassian.net/wiki/spaces/SP/pages/789"
assert_eq "TC-F13 no effect on filename" "mr-622_review.md" "$OUTPUT_FILE"

print_summary
