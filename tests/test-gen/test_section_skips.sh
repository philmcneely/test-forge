#!/usr/bin/env bash
# tests/test-gen/test_section_skips.sh
# Tests section content checks and mode switching for test-gen.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/../../skills/test-gen" && pwd)"

source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

echo "=== TC-S: Section Content Tests (test-gen) ==="
echo ""

# ── TC-S01: always.md references PROMPT_MODE ─────────────────────
ALWAYS_FILE="$SKILL_DIR/sections/always.md"
if [[ -f "$ALWAYS_FILE" ]]; then
  if grep -q "PROMPT_MODE" "$ALWAYS_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S01 always.md references PROMPT_MODE"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S01 always.md missing PROMPT_MODE"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S01 always.md not yet created"
fi

# ── TC-S02: always.md references GHERKIN ─────────────────────────
if [[ -f "$ALWAYS_FILE" ]]; then
  if grep -q "GHERKIN" "$ALWAYS_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S02 always.md references GHERKIN"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S02 always.md missing GHERKIN"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S02 always.md not yet created"
fi

# ── TC-S03: always.md references NO_SYSTEM_CONTEXT ───────────────
if [[ -f "$ALWAYS_FILE" ]]; then
  if grep -q "NO_SYSTEM_CONTEXT\|no-system-context" "$ALWAYS_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S03 always.md references NO_SYSTEM_CONTEXT"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S03 always.md missing NO_SYSTEM_CONTEXT"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S03 always.md not yet created"
fi

# ── TC-S04: prompt.md references Rovo or copy/paste prompt ───────
PROMPT_FILE="$SKILL_DIR/sections/prompt.md"
if [[ -f "$PROMPT_FILE" ]]; then
  if grep -q "Rovo\|prompt\|copy" "$PROMPT_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S04 prompt.md references Rovo/copy-paste prompt"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S04 prompt.md missing Rovo/prompt reference"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S04 prompt.md not yet created"
fi

# ── TC-S05: prompt.md references copilot-prompt.md ───────────────
if [[ -f "$PROMPT_FILE" ]]; then
  if grep -q "copilot-prompt" "$PROMPT_FILE"; then
    echo -e "${GREEN}PASS${NC}  TC-S05 prompt.md references copilot-prompt file"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S05 prompt.md missing copilot-prompt reference"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S05 prompt.md not yet created"
fi

# ── TC-S06: file.md covers PDF extraction ────────────────────────
FILE_SECTION="$SKILL_DIR/sections/file.md"
if [[ -f "$FILE_SECTION" ]]; then
  if grep -q "PDF\|pdf" "$FILE_SECTION" && grep -q "pdfminer\|extract" "$FILE_SECTION"; then
    echo -e "${GREEN}PASS${NC}  TC-S06 file.md covers PDF extraction"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S06 file.md missing PDF extraction"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S06 file.md not yet created"
fi

# ── TC-S07: file.md covers docx and xlsx ─────────────────────────
if [[ -f "$FILE_SECTION" ]]; then
  if grep -q "docx" "$FILE_SECTION" && grep -q "xlsx" "$FILE_SECTION"; then
    echo -e "${GREEN}PASS${NC}  TC-S07 file.md covers .docx and .xlsx"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S07 file.md missing .docx or .xlsx"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S07 file.md not yet created"
fi

# ── TC-S08: file.md has word count guards (50 and 8000) ──────────
if [[ -f "$FILE_SECTION" ]]; then
  if grep -q "50" "$FILE_SECTION" && grep -q "8000" "$FILE_SECTION"; then
    echo -e "${GREEN}PASS${NC}  TC-S08 file.md has word count guards (50 and 8000)"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S08 file.md missing word count guards"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S08 file.md not yet created"
fi

# ── TC-S09: file.md has Visio handling ───────────────────────────
if [[ -f "$FILE_SECTION" ]]; then
  if grep -q "Visio\|vsdx\|vsd" "$FILE_SECTION"; then
    echo -e "${GREEN}PASS${NC}  TC-S09 file.md handles Visio files"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S09 file.md missing Visio handling"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S09 file.md not yet created"
fi

# ── TC-S10: file.md has Python executable detection ──────────────
if [[ -f "$FILE_SECTION" ]]; then
  if grep -q "python3\|PYEXE\|python" "$FILE_SECTION"; then
    echo -e "${GREEN}PASS${NC}  TC-S10 file.md has Python executable detection"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  TC-S10 file.md missing Python executable detection"
    FAIL=$((FAIL + 1))
  fi
else
  echo -e "${YELLOW}SKIP${NC}  TC-S10 file.md not yet created"
fi

# ── TC-S11: mode-switching from parse_flags ───────────────────────
parse_flags
assert_eq "TC-S11a no args → PROMPT_MODE=true"   "true"  "$PROMPT_MODE"

parse_flags --prompt
assert_eq "TC-S11b --prompt → PROMPT_MODE=true"  "true"  "$PROMPT_MODE"

parse_flags --file spec.md
assert_eq "TC-S11c --file → PROMPT_MODE=false"   "false" "$PROMPT_MODE"

# ── TC-S12: section count always 2 ───────────────────────────────
parse_flags
derive_sections
assert_eq "TC-S12a prompt mode = 2 sections" "2" "${#SECTIONS_TO_LOAD[@]}"

parse_flags --file spec.md
derive_sections
assert_eq "TC-S12b file mode = 2 sections" "2" "${#SECTIONS_TO_LOAD[@]}"

parse_flags --file spec.md --no-gherkin --no-system-context --output-dir /tmp
derive_sections
assert_eq "TC-S12c all flags = 2 sections" "2" "${#SECTIONS_TO_LOAD[@]}"

print_summary
