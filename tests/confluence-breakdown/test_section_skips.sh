#!/usr/bin/env bash
# tests/confluence-breakdown/test_section_skips.sh
# Tests section content checks for confluence-breakdown.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/confluence-breakdown" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-S: Section Content Tests (confluence-breakdown) ==="
echo ""

URL="https://example.atlassian.net/wiki/spaces/SP/pages/123/My+Spec"

# ── TC-S01: always.md has --create reference ──────────────────────
ALWAYS_FILE="$SKILL_DIR/sections/always.md"
if [[ -f "$ALWAYS_FILE" ]]; then
  if grep -q "CREATE" "$ALWAYS_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S01 always.md references CREATE"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S01 always.md missing CREATE reference"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S01 always.md not yet created"
fi

# ── TC-S02: always.md has PARENT_KEY reference ────────────────────
if [[ -f "$ALWAYS_FILE" ]]; then
  if grep -q "PARENT_KEY" "$ALWAYS_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S02 always.md references PARENT_KEY"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S02 always.md missing PARENT_KEY reference"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S02 always.md not yet created"
fi

# ── TC-S03: fetch.md mentions child pages ─────────────────────────
FETCH_FILE="$SKILL_DIR/sections/fetch.md"
if [[ -f "$FETCH_FILE" ]]; then
  if grep -q "child" "$FETCH_FILE" && grep -q "PAGE_ID" "$FETCH_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S03 fetch.md covers child pages and PAGE_ID"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S03 fetch.md missing child pages or PAGE_ID"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S03 fetch.md not yet created"
fi

# ── TC-S04: analyze.md has scope sizing rules ─────────────────────
ANALYZE_FILE="$SKILL_DIR/sections/analyze.md"
if [[ -f "$ANALYZE_FILE" ]]; then
  if grep -q "Epic" "$ANALYZE_FILE" && grep -q "Story" "$ANALYZE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S04 analyze.md covers Epic and Story types"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S04 analyze.md missing Epic/Story scope rules"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S04 analyze.md not yet created"
fi

# ── TC-S05: write.md has idempotency guard ────────────────────────
WRITE_FILE="$SKILL_DIR/sections/write.md"
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "idempotency\|Idempotency\|SKIPPED\|already exists" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S05 write.md has idempotency guard"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S05 write.md missing idempotency guard"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S05 write.md not yet created"
fi

# ── TC-S06: write.md has dry run section ─────────────────────────
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "DRY RUN\|dry run\|Dry run" "$WRITE_FILE" && grep -q "confluence-breakdown\|--create" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S06 write.md has dry run reference"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S06 write.md missing dry run reference"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S06 write.md not yet created"
fi

# ── TC-S07: write.md has jira_create_issue ───────────────────────
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "jira_create_issue" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S07 write.md references jira_create_issue"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S07 write.md missing jira_create_issue"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S07 write.md not yet created"
fi

# ── TC-S08: flag defaults ─────────────────────────────────────────
parse_flags "$URL"
assert_eq "TC-S08a CREATE default=false"     "false" "$CREATE"
assert_eq "TC-S08b PARENT_KEY default empty" ""      "$PARENT_KEY"
assert_eq "TC-S08c OUTPUT_DIR default"       "output" "$OUTPUT_DIR"

# ── TC-S09: --create and --parent together ────────────────────────
parse_flags "$URL" --create --parent EPIC-99
assert_eq "TC-S09a CREATE=true"         "true"    "$CREATE"
assert_eq "TC-S09b PARENT_KEY=EPIC-99" "EPIC-99" "$PARENT_KEY"

# ── TC-S10: always 4 sections regardless of flags ────────────────
parse_flags "$URL"
derive_sections
assert_eq "TC-S10a baseline 4 sections" "4" "${#SECTIONS_TO_LOAD[@]}"

parse_flags "$URL" --create --parent PROJ-1
derive_sections
assert_eq "TC-S10b still 4 with all flags" "4" "${#SECTIONS_TO_LOAD[@]}"

print_summary
