#!/usr/bin/env bash
# tests/test-gen/test_router.sh
# Tests router section loading and flag parsing for test-gen.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/test-gen" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-R: Router Tests (test-gen) ==="
echo ""

# ── TC-R01: no args → PROMPT_MODE=true → always.md + prompt.md ───
parse_flags
derive_sections
assert_contains "TC-R01 always.md in prompt mode"  "sections/always.md"  "${SECTIONS_TO_LOAD[*]}"
assert_contains "TC-R01 prompt.md in prompt mode"  "sections/prompt.md"  "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R01 file.md NOT in prompt mode" "sections/file.md" "${SECTIONS_TO_LOAD[*]}"
assert_eq       "TC-R01 total 2 sections"           "2" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R02: --prompt → PROMPT_MODE=true → always.md + prompt.md ──
parse_flags --prompt
derive_sections
assert_contains     "TC-R02 prompt.md loaded"     "sections/prompt.md" "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R02 file.md NOT loaded"   "sections/file.md"   "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R02 total 2"              "2" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R03: --file → PROMPT_MODE=false → always.md + file.md ─────
parse_flags --file spec.md
derive_sections
assert_contains     "TC-R03 always.md loaded"    "sections/always.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains     "TC-R03 file.md loaded"      "sections/file.md"   "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R03 prompt.md NOT loaded" "sections/prompt.md" "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R03 total 2"              "2" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R04: --file --no-gherkin → file.md loaded ─────────────────
parse_flags --file spec.md --no-gherkin
derive_sections
assert_contains     "TC-R04 file.md loaded"       "sections/file.md"   "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R04 prompt.md NOT loaded"  "sections/prompt.md" "${SECTIONS_TO_LOAD[*]}"
assert_eq           "TC-R04 total 2"               "2" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-R05: --no-gherkin alone → prompt mode (no --file) ─────────
parse_flags --no-gherkin
derive_sections
assert_contains     "TC-R05 prompt.md in prompt mode" "sections/prompt.md" "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R05 file.md NOT loaded"       "sections/file.md"   "${SECTIONS_TO_LOAD[*]}"

# ── TC-R06: always.md is always the first section ─────────────────
parse_flags
derive_sections
assert_eq "TC-R06a always.md first (prompt)" "sections/always.md" "${SECTIONS_TO_LOAD[0]}"

parse_flags --file spec.md
derive_sections
assert_eq "TC-R06b always.md first (file)" "sections/always.md" "${SECTIONS_TO_LOAD[0]}"

# ── TC-R07: prompt.md and file.md are mutually exclusive ─────────
parse_flags --file spec.md
derive_sections
HAS_PROMPT="${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R07 file mode never loads prompt.md" "sections/prompt.md" "$HAS_PROMPT"

parse_flags
derive_sections
HAS_FILE="${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-R07 prompt mode never loads file.md" "sections/file.md" "$HAS_FILE"

# ── TC-C01: flag defaults ─────────────────────────────────────────
parse_flags
assert_eq "TC-C01a PROMPT_MODE default=true"         "true"   "$PROMPT_MODE"
assert_eq "TC-C01b GHERKIN default=true"              "true"   "$GHERKIN"
assert_eq "TC-C01c NO_SYSTEM_CONTEXT default=false"   "false"  "$NO_SYSTEM_CONTEXT"
assert_eq "TC-C01d OUTPUT_DIR default=output"         "output" "$OUTPUT_DIR"

# ── TC-C02: --file sets PROMPT_MODE=false ────────────────────────
parse_flags --file myspec.md
assert_eq "TC-C02 PROMPT_MODE=false" "false" "$PROMPT_MODE"
assert_eq "TC-C02 FILE_PATH set"     "myspec.md" "$FILE_PATH"

# ── TC-C03: --no-gherkin sets GHERKIN=false ───────────────────────
parse_flags --file spec.md --no-gherkin
assert_eq "TC-C03 GHERKIN=false" "false" "$GHERKIN"

# ── TC-C04: --no-system-context sets flag ────────────────────────
parse_flags --file spec.md --no-system-context
assert_eq "TC-C04 NO_SYSTEM_CONTEXT=true" "true" "$NO_SYSTEM_CONTEXT"

# ── TC-C05: --output-dir sets OUTPUT_DIR ─────────────────────────
parse_flags --file spec.md --output-dir /custom
assert_eq "TC-C05 OUTPUT_DIR=/custom" "/custom" "$OUTPUT_DIR"

print_summary
