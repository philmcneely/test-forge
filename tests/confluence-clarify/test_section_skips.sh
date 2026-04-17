#!/usr/bin/env bash
# tests/confluence-clarify/test_section_skips.sh
# Tests section content checks for confluence-clarify.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/confluence-clarify" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-S: Section Content Tests (confluence-clarify) ==="
echo ""

URL="https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec"

# ── TC-S01: always.md references CREATE ──────────────────────────
ALWAYS_FILE="$SKILL_DIR/sections/always.md"
if [[ -f "$ALWAYS_FILE" ]]; then
  if grep -q "CREATE" "$ALWAYS_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S01 always.md references CREATE"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S01 always.md missing CREATE"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S01 always.md not yet created"
fi

# ── TC-S02: fetch.md covers child pages ───────────────────────────
FETCH_FILE="$SKILL_DIR/sections/fetch.md"
if [[ -f "$FETCH_FILE" ]]; then
  if grep -q "child" "$FETCH_FILE" && grep -q "PAGE_ID" "$FETCH_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S02 fetch.md covers child pages"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S02 fetch.md missing child pages or PAGE_ID"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S02 fetch.md not yet created"
fi

# ── TC-S03: generate.md has question format instructions ─────────
GEN_FILE="$SKILL_DIR/sections/generate.md"
if [[ -f "$GEN_FILE" ]]; then
  if grep -q "Question:" "$GEN_FILE" && grep -q "Impact:" "$GEN_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S03 generate.md has question format"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S03 generate.md missing question format"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S03 generate.md not yet created"
fi

# ── TC-S04: generate.md minimum question count ───────────────────
if [[ -f "$GEN_FILE" ]]; then
  if grep -q "8\|minimum\|Minimum\|least 8" "$GEN_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S04 generate.md specifies minimum question count"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S04 generate.md missing minimum question count"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S04 generate.md not yet created"
fi

# ── TC-S05: write.md has DRY RUN preview ─────────────────────────
WRITE_FILE="$SKILL_DIR/sections/write.md"
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "DRY RUN" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S05 write.md has DRY RUN preview"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S05 write.md missing DRY RUN preview"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S05 write.md not yet created"
fi

# ── TC-S06: write.md has double-submit guard ─────────────────────
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "confluence-clarify\]" "$WRITE_FILE" && grep -q "double\|Double\|guard\|Guard" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S06 write.md has double-submit guard with tool signature"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S06 write.md missing double-submit guard or tool signature"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S06 write.md not yet created"
fi

# ── TC-S07: write.md has confluence_add_comment ──────────────────
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "confluence_add_comment" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S07 write.md references confluence_add_comment"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S07 write.md missing confluence_add_comment"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S07 write.md not yet created"
fi

# ── TC-S08: write.md mentions Round tracking ─────────────────────
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "Round" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S08 write.md has Round tracking"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S08 write.md missing Round tracking"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S08 write.md not yet created"
fi

# ── TC-S09: flag defaults ─────────────────────────────────────────
parse_flags "$URL"
assert_eq "TC-S09a CREATE default=false" "false"  "$CREATE"
assert_eq "TC-S09b OUTPUT_DIR default"   "output" "$OUTPUT_DIR"

# ── TC-S10: sections count is always 4 ───────────────────────────
parse_flags "$URL"
derive_sections
assert_eq "TC-S10a baseline 4" "4" "${#SECTIONS_TO_LOAD[@]}"

parse_flags "$URL" --create
derive_sections
assert_eq "TC-S10b 4 with --create" "4" "${#SECTIONS_TO_LOAD[@]}"

print_summary
