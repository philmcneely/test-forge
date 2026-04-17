#!/usr/bin/env bash
# tests/jira-clarify/helpers/flag_parser.sh
# Mirrors Step 0 logic in skills/jira-clarify/sections/always.md.

parse_flags() {
  JIRA_KEY=""
  CREATE=false
  OUTPUT_DIR="output"

  local args=("$@")
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    case "${args[$i]}" in
      --create)    CREATE=true ;;
      --output-dir)
        i=$((i + 1))
        OUTPUT_DIR="${args[$i]}"
        ;;
      [A-Z]*-[0-9]*) JIRA_KEY="${args[$i]}" ;;
    esac
    i=$((i + 1))
  done

  # Derive PROJECT_KEY
  PROJECT_KEY="${JIRA_KEY%%-*}"

  OUTPUT_FILE="${JIRA_KEY}_clarify.md"
}

derive_sections() {
  SECTIONS_TO_LOAD=(
    "sections/always.md"
    "sections/fetch.md"
    "sections/generate.md"
    "sections/write.md"
  )
}
