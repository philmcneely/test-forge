#!/usr/bin/env bash
# TC-S: Section skip rules and flag implication tests
# Verifies flag implications, variable derivation, and that skip instructions
# are present in the correct section files once they exist.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers/mock_env.sh"
source "$SCRIPT_DIR/helpers/flag_parser.sh"

SKILL_ROOT="$(cd "$SCRIPT_DIR/../../skills/jira-test-gen" && pwd)"

echo "=== TC-S: Section Skip and Flag Implication Tests ==="
echo ""

# ── TC-S01/S02: --neg-only implies --no-clarify ────────────────────────────
parse_flags "PROJ-123" "--neg-only"
assert_eq "TC-S01 NEG_ONLY=true"                            "true"  "$NEG_ONLY"
assert_eq "TC-S02 NO_CLARIFY=true (implied by --neg-only)"  "true"  "$NO_CLARIFY"

# ── TC-S03: --no-clarify alone does not set neg-only ──────────────────────
parse_flags "PROJ-123" "--no-clarify"
assert_eq "TC-S03a NO_CLARIFY=true"  "true"  "$NO_CLARIFY"
assert_eq "TC-S03b NEG_ONLY=false"   "false" "$NEG_ONLY"

# ── TC-S04–S07: NEG_ONLY routes away from sections-happy.md ───────────────
# Sections 3, 8, 10 live in sections-happy.md; absence = skip
parse_flags "PROJ-123" "--neg-only"; derive_sections
assert_contains     "TC-S04 sections-meta.md loaded (manages Section 1 skip)" \
  "sections/sections-meta.md" "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-S05 Section 3 absent (sections-happy.md not loaded)" \
  "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-S06 Section 8 absent (sections-happy.md not loaded)" \
  "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_not_contains "TC-S07 Section 10 absent (sections-happy.md not loaded)" \
  "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"

# ── TC-S08: --no-clarify alone keeps sections-happy.md (Section 3 present) ─
parse_flags "PROJ-123" "--no-clarify"; derive_sections
assert_contains "TC-S08 sections-happy.md loaded with --no-clarify" \
  "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"

# ── TC-S09: Standard mode — sections-meta.md loaded, NO_CLARIFY=false ─────
parse_flags "PROJ-123"; derive_sections
assert_contains "TC-S09 sections-meta.md loaded"  "sections/sections-meta.md" "${SECTIONS_TO_LOAD[*]}"
assert_eq       "TC-S09 NO_CLARIFY=false"         "false" "$NO_CLARIFY"

# ── TC-S10: NEG_ONLY=true is set for write.md to skip Step 8 ──────────────
parse_flags "PROJ-123" "--neg-only"
assert_eq "TC-S10 NEG_ONLY=true (write.md will skip Step 8)" "true" "$NEG_ONLY"

# ── TC-S11: --neg-only --create → NO_CLARIFY=true (Step 7 will be skipped) ─
parse_flags "PROJ-123" "--neg-only" "--create"
assert_eq "TC-S11a CREATE=true"                                  "true" "$CREATE"
assert_eq "TC-S11b NO_CLARIFY=true (Step 7 in write.md skipped)" "true" "$NO_CLARIFY"

# ── TC-S12: FOLLOW=false → fetch-follow.md absent ─────────────────────────
parse_flags "PROJ-123"; derive_sections
assert_not_contains "TC-S12 fetch-follow.md absent when FOLLOW=false" \
  "sections/fetch-follow.md" "${SECTIONS_TO_LOAD[*]}"

# ── TC-S13: --no-clarify --follow → happy sections still loaded ───────────
parse_flags "PROJ-123" "--no-clarify" "--follow"; derive_sections
assert_eq        "TC-S13a FOLLOW=true"                  "true" "$FOLLOW"
assert_eq        "TC-S13b NO_CLARIFY=true"              "true" "$NO_CLARIFY"
assert_contains  "TC-S13c sections-happy.md loaded"     "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_contains  "TC-S13d fetch-follow.md loaded"       "sections/fetch-follow.md"   "${SECTIONS_TO_LOAD[*]}"

# ── TC-S14: --neg-only --no-clarify (redundant) same as --neg-only alone ──
parse_flags "PROJ-123" "--neg-only" "--no-clarify"; derive_sections
assert_not_contains "TC-S14 sections-happy still absent" \
  "sections/sections-happy.md" "${SECTIONS_TO_LOAD[*]}"
assert_eq "TC-S14 same 6 sections as --neg-only alone" "6" "${#SECTIONS_TO_LOAD[@]}"

# ── TC-S15/S16/S17: Verify skip instructions present in section files ──────
# These run in YELLOW/SKIP mode before the files are created,
# and pass properly once the files exist.

if [[ -f "$SKILL_ROOT/sections/sections-meta.md" ]]; then
  content=$(cat "$SKILL_ROOT/sections/sections-meta.md")
  assert_contains "TC-S15 Section 1 skip instruction in sections-meta.md" \
    "NO_CLARIFY" "$content"
  assert_contains "TC-S17 Progression Tests NEG_ONLY instruction in sections-meta.md" \
    "NEG_ONLY" "$content"
else
  echo -e "${YELLOW}SKIP${NC}  TC-S15 — sections/sections-meta.md not created yet"
  echo -e "${YELLOW}SKIP${NC}  TC-S17 — sections/sections-meta.md not created yet"
fi

if [[ -f "$SKILL_ROOT/sections/format.md" ]]; then
  content=$(cat "$SKILL_ROOT/sections/format.md")
  assert_contains "TC-S16 NEG_ONLY skip list in format.md" "NEG_ONLY" "$content"
else
  echo -e "${YELLOW}SKIP${NC}  TC-S16 — sections/format.md not created yet"
fi

# ── TC-S18: sections-neg.md always loaded (even with --neg-only) ──────────
parse_flags "PROJ-123" "--neg-only"; derive_sections
assert_contains "TC-S18 sections-neg.md always loaded" \
  "sections/sections-neg.md" "${SECTIONS_TO_LOAD[*]}"

# ── TC-S19: GHERKIN flag set correctly ────────────────────────────────────
parse_flags "PROJ-123";              assert_eq "TC-S19a GHERKIN default=true"       "true"  "$GHERKIN"
parse_flags "PROJ-123" "--no-gherkin"; assert_eq "TC-S19b GHERKIN=false with flag"  "false" "$GHERKIN"

# ── TC-S20: CREATE flag set correctly ─────────────────────────────────────
parse_flags "PROJ-123";           assert_eq "TC-S20a CREATE default=false" "false" "$CREATE"
parse_flags "PROJ-123" "--create"; assert_eq "TC-S20b CREATE=true with flag" "true" "$CREATE"

echo ""
print_summary
