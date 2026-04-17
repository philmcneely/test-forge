#!/usr/bin/env bash
# tests/confluence-breakdown/test_filenames.sh
# Tests output filename derivation for confluence-breakdown.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-F: Filename Tests (confluence-breakdown) ==="
echo ""

URL="https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec"

# ── TC-F01: base filename uses slug derived from URL ──────────────
parse_flags "$URL"
assert_eq "TC-F01 OUTPUT_FILE prefix"    "confluence-" "${OUTPUT_FILE:0:11}"
assert_eq "TC-F01 OUTPUT_FILE suffix"    "_tickets.md" "${OUTPUT_FILE: -11}"

# ── TC-F02: --create does not change OUTPUT_FILE ─────────────────
parse_flags "$URL" --create
BASE="$OUTPUT_FILE"
parse_flags "$URL"
assert_eq "TC-F02 --create no effect" "$OUTPUT_FILE" "$BASE"

# ── TC-F03: --parent does not change OUTPUT_FILE ─────────────────
parse_flags "$URL" --parent PROJ-10
PARENT_FILE="$OUTPUT_FILE"
parse_flags "$URL"
assert_eq "TC-F03 --parent no effect" "$OUTPUT_FILE" "$PARENT_FILE"

# ── TC-F04: different URL slug produces different filename ────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/456/Another+Page"
FILE_A="$OUTPUT_FILE"
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/789/Yet+Another"
FILE_B="$OUTPUT_FILE"
assert_eq "TC-F04 filenames differ" "true" "$([[ "$FILE_A" != "$FILE_B" ]] && echo true || echo false)"

# ── TC-F05: --output-dir does not change OUTPUT_FILE base ────────
parse_flags "$URL" --output-dir /tmp/out
assert_eq "TC-F05a OUTPUT_DIR set"     "/tmp/out"    "$OUTPUT_DIR"
assert_eq "TC-F05b OUTPUT_FILE prefix" "confluence-" "${OUTPUT_FILE:0:11}"

# ── TC-F06: all flags together — filename still same as no flags ──
parse_flags "$URL"
NOFLAGS="$OUTPUT_FILE"
parse_flags "$URL" --create --parent PROJ-10 --output-dir /tmp
assert_eq "TC-F06 all flags no effect on filename" "$NOFLAGS" "$OUTPUT_FILE"

print_summary
