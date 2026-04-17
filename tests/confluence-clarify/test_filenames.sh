#!/usr/bin/env bash
# tests/confluence-clarify/test_filenames.sh
# Tests output filename derivation for confluence-clarify.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-F: Filename Tests (confluence-clarify) ==="
echo ""

URL="https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec"

# ── TC-F01: base filename has confluence- prefix and _clarify.md suffix
parse_flags "$URL"
assert_eq "TC-F01 prefix"  "confluence-" "${OUTPUT_FILE:0:11}"
assert_eq "TC-F01 suffix"  "_clarify.md" "${OUTPUT_FILE: -11}"

# ── TC-F02: --create does not affect filename ─────────────────────
parse_flags "$URL"
NOFLAGS="$OUTPUT_FILE"
parse_flags "$URL" --create
assert_eq "TC-F02 --create no effect" "$NOFLAGS" "$OUTPUT_FILE"

# ── TC-F03: --output-dir does not change OUTPUT_FILE base ────────
parse_flags "$URL" --output-dir /tmp/clarify
assert_eq "TC-F03a OUTPUT_DIR set"   "/tmp/clarify" "$OUTPUT_DIR"
assert_eq "TC-F03b suffix unchanged" "_clarify.md"  "${OUTPUT_FILE: -11}"

# ── TC-F04: different URLs produce different filenames ───────────
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/111/Feature+A"
FILE_A="$OUTPUT_FILE"
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/222/Feature+B"
FILE_B="$OUTPUT_FILE"
assert_eq "TC-F04 different slugs differ" "true" "$([[ "$FILE_A" != "$FILE_B" ]] && echo true || echo false)"

# ── TC-F05: slug max 60 chars (content between confluence- and _clarify.md)
parse_flags "https://example.atlassian.net/wiki/spaces/SP/pages/123/This+Is+A+Very+Long+Page+Title+That+Exceeds+Sixty+Characters+For+Sure"
SLUG_PART="${OUTPUT_FILE#confluence-}"
SLUG_PART="${SLUG_PART%_clarify.md}"
assert_eq "TC-F05 slug max 60" "true" "$([[ ${#SLUG_PART} -le 60 ]] && echo true || echo false)"

print_summary
