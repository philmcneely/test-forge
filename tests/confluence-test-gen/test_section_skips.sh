#!/usr/bin/env bash
# tests/confluence-test-gen/test_section_skips.sh
# Tests section skip logic and content checks for confluence-test-gen.
# Usage: bash tests/confluence-test-gen/test_section_skips.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/confluence-test-gen" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-S: Section Skip and Flag Implication Tests (confluence-test-gen) ==="
echo ""

URL="https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec"

# ── TC-S01: --neg-only sets NEG_ONLY and NO_CLARIFY ──────────────
parse_flags "$URL" --neg-only
derive_sections
assert_eq "TC-S01 NEG_ONLY=true"    "true" "$NEG_ONLY"
assert_eq "TC-S02 NO_CLARIFY=true"  "true" "$NO_CLARIFY"

# ── TC-S03: --no-clarify alone sets NO_CLARIFY, not NEG_ONLY ─────
parse_flags "$URL" --no-clarify
assert_eq "TC-S03a NO_CLARIFY=true"  "true"  "$NO_CLARIFY"
assert_eq "TC-S03b NEG_ONLY=false"   "false" "$NEG_ONLY"

# ── TC-S04: sections-meta.md always loaded (manages Section 1 skip)
parse_flags "$URL"
derive_sections
assert_contains "TC-S04 sections-meta.md loaded" "sections/sections-meta.md" "${SECTIONS_TO_LOAD[*]}"

# ── TC-S05–S07: --neg-only → sections-happy absent (Sections 3,8,10 gone)
parse_flags "$URL" --neg-only
derive_sections
assert_not_contains "TC-S05 Section 3 absent" "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-S06 Section 8 absent" "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-S07 Section 10 absent" "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"

# ── TC-S08: --no-clarify does NOT drop sections-happy ────────────
parse_flags "$URL" --no-clarify
derive_sections
assert_contains "TC-S08 sections-happy.md loaded with --no-clarify" "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"

# ── TC-S09: sections-meta.md always present ───────────────────────
parse_flags "$URL"
derive_sections
assert_contains "TC-S09a sections-meta.md loaded"  "sections/sections-meta.md" "${SECTIONS_TO_LOAD[*]}"
assert_eq       "TC-S09b NO_CLARIFY=false"         "false" "$NO_CLARIFY"

# ── TC-S10: --no-testdata → testdata.md not loaded ───────────────
parse_flags "$URL" --no-testdata
derive_sections
assert_eq           "TC-S10a NO_TESTDATA=true"        "true" "$NO_TESTDATA"
assert_not_contains "TC-S10b testdata NOT loaded"     "sections/testdata.md" "${SECTIONS_TO_LOAD[*]}"

# ── TC-S11: --testdata-only → testdata.md loaded (content guarded)
parse_flags "$URL" --testdata-only
derive_sections
assert_eq       "TC-S11a TESTDATA_ONLY=true"      "true" "$TESTDATA_ONLY"
assert_contains "TC-S11b testdata.md loaded"      "sections/testdata.md" "${SECTIONS_TO_LOAD[*]}"

# ── TC-S12: --include-children flag set, section set unchanged ───
parse_flags "$URL" --include-children
derive_sections
assert_eq "TC-S12 INCLUDE_CHILDREN=true" "true" "$INCLUDE_CHILDREN"
assert_eq "TC-S12 total 8 sections"      "8"    "${#SECTIONS_TO_LOAD[@]}"

# ── TC-S13: GHERKIN defaults to true ─────────────────────────────
parse_flags "$URL"
assert_eq "TC-S13a GHERKIN default=true"  "true"  "$GHERKIN"

parse_flags "$URL" --no-gherkin
assert_eq "TC-S13b GHERKIN=false with flag" "false" "$GHERKIN"

# ── TC-S14: CREATE defaults to false ─────────────────────────────
parse_flags "$URL"
assert_eq "TC-S14a CREATE default=false" "false" "$CREATE"

parse_flags "$URL" --create
assert_eq "TC-S14b CREATE=true with flag" "true" "$CREATE"

# ── TC-S15: Section 1 skip instruction in sections-meta.md ───────
META_FILE="$SKILL_DIR/sections/sections-meta.md"
if [[ -f "$META_FILE" ]]; then
  if grep -q "NO_CLARIFY" "$META_FILE" && grep -q "NEG_ONLY" "$META_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S15 Section 1 skip instruction in sections-meta.md"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S15 sections-meta.md missing NO_CLARIFY/NEG_ONLY skip instruction"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S15 sections-meta.md not yet created"
fi

# ── TC-S16: NEG_ONLY skip list in format.md ───────────────────────
FORMAT_FILE="$SKILL_DIR/sections/format.md"
if [[ -f "$FORMAT_FILE" ]]; then
  if grep -q "NEG_ONLY" "$FORMAT_FILE" && grep -q "Sections 1, 3, 8" "$FORMAT_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S16 NEG_ONLY skip list in format.md"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S16 format.md missing NEG_ONLY skip list"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S16 format.md not yet created"
fi

# ── TC-S17: Progression Tests instruction in sections-meta.md ────
if [[ -f "$META_FILE" ]]; then
  if grep -q "Progression Tests" "$META_FILE" && grep -q "NEG_ONLY" "$META_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S17 Progression Tests NEG_ONLY instruction in sections-meta.md"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S17 sections-meta.md missing Progression Tests NEG_ONLY instruction"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S17 sections-meta.md not yet created"
fi

# ── TC-S18: testdata.md has NO_TESTDATA guard ────────────────────
TESTDATA_FILE_PATH="$SKILL_DIR/sections/testdata.md"
if [[ -f "$TESTDATA_FILE_PATH" ]]; then
  if grep -q "NO_TESTDATA" "$TESTDATA_FILE_PATH"; then
    echo -e "${GREEN}PASS${NC}  TC-S18 testdata.md has NO_TESTDATA guard"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S18 testdata.md missing NO_TESTDATA guard"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S18 testdata.md not yet created"
fi

# ── TC-S19: sections-neg.md always loaded across combos ──────────
assert_eq "TC-S19 sections-neg always (baseline)" "1" \
  "$(parse_flags "$URL"; derive_sections; printf '%s\n' "${SECTIONS_TO_LOAD[@]}" | grep -c sections-neg || true)"

print_summary
