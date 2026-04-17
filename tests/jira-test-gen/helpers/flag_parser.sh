#!/usr/bin/env bash
# Flag parser — mirrors the logic defined in sections/always.md Step 0.
# Sourced by test scripts; accepts the same argv as the skill invocation.
#
# Usage:
#   source flag_parser.sh
#   parse_flags "PROJ-123" "--neg-only" "--follow"
#   derive_sections
#   echo "$OUTPUT_FILE"
#   echo "${SECTIONS_TO_LOAD[*]}"

parse_flags() {
  local args=("$@")

  # ── Reset all variables ────────────────────────────────────────────────────
  KEY=""
  CREATE=false
  GHERKIN=true
  FOLLOW=false
  BLACKBOX=false
  NO_CLARIFY=false
  NEG_ONLY=false
  OUTPUT_DIR="output"
  OUTPUT_FILE=""

  # ── First pass: extract flags ──────────────────────────────────────────────
  local i
  for ((i = 0; i < ${#args[@]}; i++)); do
    case "${args[$i]}" in
      --create)      CREATE=true ;;
      --no-gherkin)  GHERKIN=false ;;
      --follow)      FOLLOW=true ;;
      --blackbox)    BLACKBOX=true ;;
      --no-clarify)  NO_CLARIFY=true ;;
      --neg-only)    NEG_ONLY=true ;;
      --output-dir)  OUTPUT_DIR="${args[$((i+1))]:-output}"; ((i++)) ;;
      --*)           : ;;  # unknown flag — ignore
      *)             [[ -z "$KEY" ]] && KEY="${args[$i]}" ;;
    esac
  done

  # ── Implication: neg-only → no-clarify ────────────────────────────────────
  [[ "$NEG_ONLY" == true ]] && NO_CLARIFY=true

  # ── Derive OUTPUT_FILE ────────────────────────────────────────────────────
  local base="${KEY}_tests"
  [[ "$BLACKBOX"  == true  ]] && base="${base}_blackbox"
  [[ "$NEG_ONLY"  == true  ]] && base="${base}_neg"
  [[ "$GHERKIN"   == false ]] && base="${base}_no_gherkin"
  OUTPUT_FILE="${base}.md"

  # Exception: --no-clarify alone (not combined with blackbox, neg-only, or no-gherkin) → no suffix
  if [[ "$NO_CLARIFY" == true && "$BLACKBOX" == false && "$NEG_ONLY" == false && "$GHERKIN" == true ]]; then
    OUTPUT_FILE="${KEY}_tests.md"
  fi

  export KEY CREATE GHERKIN FOLLOW BLACKBOX NO_CLARIFY NEG_ONLY OUTPUT_DIR OUTPUT_FILE
}

# ── Derive which section files to load ────────────────────────────────────────
# Must be called AFTER parse_flags.
derive_sections() {
  SECTIONS_TO_LOAD=(
    "sections/always.md"
    "sections/fetch.md"
    "sections/format.md"
    "sections/sections-neg.md"
    "sections/sections-meta.md"
    "sections/write.md"
  )

  [[ "$FOLLOW"   == true  ]] && SECTIONS_TO_LOAD+=("sections/fetch-follow.md")
  [[ "$NEG_ONLY" == false ]] && SECTIONS_TO_LOAD+=("sections/sections-happy.md")

  export SECTIONS_TO_LOAD
}
