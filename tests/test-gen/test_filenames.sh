#!/usr/bin/env bash
# tests/test-gen/test_filenames.sh
# Tests output filename derivation for test-gen.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-F: Filename Tests (test-gen) ==="
echo ""

# ── TC-F01: --file spec.md → spec_tests.md ───────────────────────
parse_flags --file spec.md
assert_eq "TC-F01 spec.md → spec_tests.md" "spec_tests.md" "$OUTPUT_FILE"

# ── TC-F02: --file spec.md --no-gherkin → spec_tests_no_gherkin.md
parse_flags --file spec.md --no-gherkin
assert_eq "TC-F02 no-gherkin suffix" "spec_tests_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F03: --file My Feature.pdf → My_Feature_tests.md ──────────
parse_flags --file "My Feature.pdf"
assert_eq "TC-F03 spaces → underscores" "My_Feature_tests.md" "$OUTPUT_FILE"

# ── TC-F04: --file path/to/spec.md → spec_tests.md ───────────────
parse_flags --file "path/to/spec.md"
assert_eq "TC-F04 path stripped" "spec_tests.md" "$OUTPUT_FILE"

# ── TC-F05: --file my.spec.doc.md → my_spec_doc_tests.md ─────────
parse_flags --file "my.spec.doc.md"
assert_eq "TC-F05 dots become underscores" "my_spec_doc_tests.md" "$OUTPUT_FILE"

# ── TC-F06: prompt mode → no OUTPUT_FILE ─────────────────────────
parse_flags
assert_eq "TC-F06 prompt mode no output file" "" "$OUTPUT_FILE"

parse_flags --prompt
assert_eq "TC-F06b --prompt no output file" "" "$OUTPUT_FILE"

# ── TC-F07: --output-dir does not change OUTPUT_FILE base ────────
parse_flags --file spec.md --output-dir /tmp/out
assert_eq "TC-F07a OUTPUT_DIR"      "/tmp/out"      "$OUTPUT_DIR"
assert_eq "TC-F07b OUTPUT_FILE"     "spec_tests.md" "$OUTPUT_FILE"

# ── TC-F08: --no-gherkin + --output-dir ──────────────────────────
parse_flags --file spec.md --no-gherkin --output-dir /tmp
assert_eq "TC-F08 no-gherkin + dir" "spec_tests_no_gherkin.md" "$OUTPUT_FILE"

# ── TC-F09: different file extensions all stripped ────────────────
parse_flags --file "report.pdf"
assert_eq "TC-F09a pdf" "report_tests.md" "$OUTPUT_FILE"

parse_flags --file "document.docx"
assert_eq "TC-F09b docx" "document_tests.md" "$OUTPUT_FILE"

parse_flags --file "data.xlsx"
assert_eq "TC-F09c xlsx" "data_tests.md" "$OUTPUT_FILE"

parse_flags --file "notes.txt"
assert_eq "TC-F09d txt" "notes_tests.md" "$OUTPUT_FILE"

# ── TC-F10: --no-system-context does not affect filename ─────────
parse_flags --file spec.md --no-system-context
assert_eq "TC-F10 no-system-context no effect" "spec_tests.md" "$OUTPUT_FILE"

print_summary
