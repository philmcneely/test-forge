#!/usr/bin/env bash
# helpers/flag_parser.sh — Standalone flag parser for mr-review router tests.
# Mirrors the Step 0 logic in skills/mr-review/sections/always.md.
# Source this file, then call parse_flags "$@" and derive_sections.

parse_flags() {
  # Reset all variables
  MR_URL=""
  JIRA_KEY=""
  CONFLUENCE_URL=""
  CREATE=false
  GHERKIN=true
  BLACKBOX=false
  GITLAB=false
  GITHUB=false
  MR_ID=""
  OUTPUT_DIR="output"

  local args=("$@")
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    case "${args[$i]}" in
      --create)      CREATE=true ;;
      --no-gherkin)  GHERKIN=false ;;
      --blackbox)    BLACKBOX=true ;;
      --jira)
        i=$((i + 1))
        JIRA_KEY="${args[$i]}"
        ;;
      --confluence)
        i=$((i + 1))
        CONFLUENCE_URL="${args[$i]}"
        ;;
      --output-dir)
        i=$((i + 1))
        OUTPUT_DIR="${args[$i]}"
        ;;
      http*)
        MR_URL="${args[$i]}"
        # Detect platform
        if [[ "$MR_URL" == *merge_requests* ]]; then
          GITLAB=true
        elif [[ "$MR_URL" == */pull/* ]]; then
          GITHUB=true
        fi
        # Extract MR_ID (trailing numeric segment)
        MR_ID="${MR_URL##*/}"
        # Handle trailing slashes or query strings
        MR_ID="${MR_ID%%\?*}"
        MR_ID="${MR_ID%%/*}"
        ;;
    esac
    i=$((i + 1))
  done

  # Derive OUTPUT_FILE
  local base="mr-${MR_ID}_review"
  [[ "$BLACKBOX" == true  ]] && base="${base}_blackbox"
  [[ "$GHERKIN"  == false ]] && base="${base}_no_gherkin"
  OUTPUT_FILE="${base}.md"
}

derive_sections() {
  # mr-review always loads all 5 section files — no conditional loading
  SECTIONS_TO_LOAD=(
    "sections/always.md"
    "sections/fetch.md"
    "sections/format.md"
    "sections/sections.md"
    "sections/write.md"
  )
}
