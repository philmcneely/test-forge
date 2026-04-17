#!/usr/bin/env bash
# tests/mr-review/test_section_skips.sh
# Tests section content checks for mr-review.
# Usage: bash tests/mr-review/test_section_skips.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/mr-review" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-S: Section Content Tests (mr-review) ==="
echo ""

GL="https://gitlab.company.net/group/repo/-/merge_requests/622"

# ── TC-S01: always.md contains BLACKBOX flag reference ───────────
ALWAYS_FILE="$SKILL_DIR/sections/always.md"
if [[ -f "$ALWAYS_FILE" ]]; then
  if grep -q "BLACKBOX" "$ALWAYS_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S01 always.md references BLACKBOX"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S01 always.md missing BLACKBOX reference"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S01 always.md not yet created"
fi

# ── TC-S02: format.md contains BLACKBOX language rules ───────────
FORMAT_FILE="$SKILL_DIR/sections/format.md"
if [[ -f "$FORMAT_FILE" ]]; then
  if grep -q "BLACKBOX" "$FORMAT_FILE" && grep -q "observable" "$FORMAT_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S02 format.md has BLACKBOX language rules"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S02 format.md missing BLACKBOX language rules"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S02 format.md not yet created"
fi

# ── TC-S03: sections.md has all 10 sections ───────────────────────
SECTIONS_FILE="$SKILL_DIR/sections/sections.md"
if [[ -f "$SECTIONS_FILE" ]]; then
  # Check for sections 1 through 10
  missing=0
  for n in 1 2 3 4 5 6 7 8 9 10; do
    if ! grep -q "Section $n" "$SECTIONS_FILE"; then
      echo -e "${RED}FAIL${NC}  TC-S03 sections.md missing Section $n"
      FAIL=$((FAIL + 1))
      missing=$((missing + 1))
    fi
  done
  if [[ $missing -eq 0 ]]; then
    echo -e "${GREEN}PASS${NC}  TC-S03 sections.md has all 10 sections"
    PASS=$((PASS + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S03 sections.md not yet created"
fi

# ── TC-S04: sections.md contains 4 subsections for Section 7 ─────
if [[ -f "$SECTIONS_FILE" ]]; then
  if grep -q "7a\." "$SECTIONS_FILE" && grep -q "7b\." "$SECTIONS_FILE" && \
     grep -q "7c\." "$SECTIONS_FILE" && grep -q "7d\." "$SECTIONS_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S04 sections.md has 7a–7d subsections"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S04 sections.md missing Section 7 subsections"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S04 sections.md not yet created"
fi

# ── TC-S05: write.md contains dry-run preview ────────────────────
WRITE_FILE="$SKILL_DIR/sections/write.md"
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "DRY RUN" "$WRITE_FILE" && grep -q "mr-review" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S05 write.md has dry-run preview and tool signature"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S05 write.md missing dry-run preview or tool signature"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S05 write.md not yet created"
fi

# ── TC-S06: fetch.md mentions both GitLab and GitHub ─────────────
FETCH_FILE="$SKILL_DIR/sections/fetch.md"
if [[ -f "$FETCH_FILE" ]]; then
  if grep -q "GitLab" "$FETCH_FILE" && grep -q "GitHub" "$FETCH_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S06 fetch.md covers GitLab and GitHub"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S06 fetch.md missing GitLab or GitHub"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S06 fetch.md not yet created"
fi

# ── TC-S07: write.md handles Jira comment post ───────────────────
if [[ -f "$WRITE_FILE" ]]; then
  if grep -q "jira_add_comment" "$WRITE_FILE" && grep -q "\-\-jira" "$WRITE_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S07 write.md posts Jira comment when --jira given"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S07 write.md missing Jira comment logic"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S07 write.md not yet created"
fi

# ── TC-S08: flag defaults ─────────────────────────────────────────
parse_flags "$GL"
assert_eq "TC-S08a CREATE default=false"  "false" "$CREATE"
assert_eq "TC-S08b GHERKIN default=true"  "true"  "$GHERKIN"
assert_eq "TC-S08c BLACKBOX default=false" "false" "$BLACKBOX"
assert_eq "TC-S08d JIRA_KEY default empty" ""     "$JIRA_KEY"

# ── TC-S09: mr-review has no NEG_ONLY flag ───────────────────────
# NEG_ONLY does not exist for mr-review — test that it's not set
parse_flags "$GL"
# If NEG_ONLY is not defined by parse_flags, it should be unset or empty
NEG_ONLY_VAL="${NEG_ONLY:-not_set}"
assert_eq "TC-S09 no NEG_ONLY in mr-review" "not_set" "$NEG_ONLY_VAL"

# ── TC-S10: no conditional section files in mr-review ────────────
parse_flags "$GL"
derive_sections
assert_eq "TC-S10 always 5 sections" "5" "${#SECTIONS_TO_LOAD[@]}"

parse_flags "$GL" --blackbox --no-gherkin --create --jira PROJ-1
derive_sections
assert_eq "TC-S10 still 5 sections with all flags" "5" "${#SECTIONS_TO_LOAD[@]}"

print_summary
