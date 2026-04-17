#!/usr/bin/env bash
# tests/jira-clarify/test_section_skips.sh
# Tests section content checks for jira-clarify.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/jira-clarify" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-S: Section Content Tests (jira-clarify) ==="
echo ""

KEY="PROJ-123"

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

# ── TC-S02: always.md references JIRA_KEY and PROJECT_KEY ────────
if [[ -f "$ALWAYS_FILE" ]]; then
  if grep -q "JIRA_KEY\|JIRA-KEY\|issue_key" "$ALWAYS_FILE" && grep -q "PROJECT_KEY" "$ALWAYS_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S02 always.md has JIRA_KEY and PROJECT_KEY"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S02 always.md missing JIRA_KEY or PROJECT_KEY"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S02 always.md not yet created"
fi

# ── TC-S03: fetch.md fetches primary ticket ───────────────────────
FETCH_FILE="$SKILL_DIR/sections/fetch.md"
if [[ -f "$FETCH_FILE" ]]; then
  if grep -q "jira_get_issue\|get_issue" "$FETCH_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S03 fetch.md uses jira_get_issue"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S03 fetch.md missing jira_get_issue"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S03 fetch.md not yet created"
fi

# ── TC-S04: fetch.md includes ADF-to-text helper ─────────────────
if [[ -f "$FETCH_FILE" ]]; then
  if grep -q "extract_text\|ADF" "$FETCH_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S04 fetch.md has ADF-to-text helper"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S04 fetch.md missing ADF-to-text helper"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S04 fetch.md not yet created"
fi

# ── TC-S05: generate.md has question format ───────────────────────
GEN_FILE="$SKILL_DIR/sections/generate.md"
if [[ -f "$GEN_FILE" ]]; then
  if grep -q "Question:" "$GEN_FILE" && grep -q "Impact:" "$GEN_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S05 generate.md has question format"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S05 generate.md missing question format"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S05 generate.md not yet created"
fi

# ── TC-S06: generate.md targets 8-12 questions ───────────────────
if [[ -f "$GEN_FILE" ]]; then
  if grep -q "8\|12\|least 8\|targeting 12" "$GEN_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S06 generate.md specifies 8-12 question target"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S06 generate.md missing 8-12 question target"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S06 generate.md not yet created"
fi

# ── TC-S07: write.md has DRY RUN preview ─────────────────────────
WRITE_FILE="$SKILL_DIR/sections/write.md"
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "DRY RUN" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S07 write.md has DRY RUN preview"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S07 write.md missing DRY RUN preview"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S07 write.md not yet created"
fi

# ── TC-S08: write.md has [jira-clarify] tool signature ───────────
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "\[jira-clarify\]" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S08 write.md has [jira-clarify] tool signature"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S08 write.md missing [jira-clarify] tool signature"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S08 write.md not yet created"
fi

# ── TC-S09: write.md has jira_add_comment ────────────────────────
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "jira_add_comment" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S09 write.md references jira_add_comment"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S09 write.md missing jira_add_comment"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S09 write.md not yet created"
fi

# ── TC-S10: write.md has double-submit guard with Round N ────────
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "Round" "$WRITE_FILE" && grep -q "double\|Double\|guard\|5 minutes" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S10 write.md has double-submit guard with Round tracking"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S10 write.md missing double-submit guard or Round tracking"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S10 write.md not yet created"
fi

# ── TC-S11: flag defaults from parse_flags ───────────────────────
parse_flags "$KEY"
assert_eq "TC-S11a JIRA_KEY=PROJ-123"  "PROJ-123" "$JIRA_KEY"
assert_eq "TC-S11b CREATE=false"        "false"    "$CREATE"
assert_eq "TC-S11c OUTPUT_DIR=output"   "output"   "$OUTPUT_DIR"
assert_eq "TC-S11d OUTPUT_FILE correct" "PROJ-123_clarify.md" "$OUTPUT_FILE"

# ── TC-S12: always 4 sections regardless of flags ────────────────
parse_flags "$KEY"
derive_sections
assert_eq "TC-S12a baseline 4" "4" "${#SECTIONS_TO_LOAD[@]}"

parse_flags "$KEY" --create
derive_sections
assert_eq "TC-S12b 4 with --create" "4" "${#SECTIONS_TO_LOAD[@]}"

print_summary
