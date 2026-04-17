#!/usr/bin/env bash
# tests/jira-clarify/test_filenames.sh
# Tests output filename derivation for jira-clarify.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-F: Filename Tests (jira-clarify) ==="
echo ""

# ── TC-F01: standard key → <KEY>_clarify.md ───────────────────────
parse_flags "PROJ-123"
assert_eq "TC-F01 PROJ-123" "PROJ-123_clarify.md" "$OUTPUT_FILE"

# ── TC-F02: different keys produce different filenames ────────────
parse_flags "ABC-456"
assert_eq "TC-F02a ABC-456" "ABC-456_clarify.md" "$OUTPUT_FILE"

parse_flags "MYTEAM-1"
assert_eq "TC-F02b MYTEAM-1" "MYTEAM-1_clarify.md" "$OUTPUT_FILE"

parse_flags "LONGPROJECT-9999"
assert_eq "TC-F02c LONGPROJECT-9999" "LONGPROJECT-9999_clarify.md" "$OUTPUT_FILE"

# ── TC-F03: --create does not affect filename ─────────────────────
parse_flags "PROJ-123"
NOFLAGS="$OUTPUT_FILE"
parse_flags "PROJ-123" --create
assert_eq "TC-F03 --create no effect" "$NOFLAGS" "$OUTPUT_FILE"

# ── TC-F04: --output-dir does not affect OUTPUT_FILE base ────────
parse_flags "PROJ-123" --output-dir /tmp/clarify
assert_eq "TC-F04a OUTPUT_DIR"       "/tmp/clarify"        "$OUTPUT_DIR"
assert_eq "TC-F04b OUTPUT_FILE same" "PROJ-123_clarify.md" "$OUTPUT_FILE"

# ── TC-F05: all flags together ────────────────────────────────────
parse_flags "PROJ-123" --create --output-dir /some/path
assert_eq "TC-F05 filename unchanged" "PROJ-123_clarify.md" "$OUTPUT_FILE"

print_summary
