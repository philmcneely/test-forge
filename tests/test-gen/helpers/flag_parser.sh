#!/usr/bin/env bash
# tests/test-gen/helpers/flag_parser.sh
# Mirrors Step 0 logic in skills/test-gen/sections/always.md.

parse_flags() {
  PROMPT_MODE=true
  FILE_PATH=""
  GHERKIN=true
  NO_SYSTEM_CONTEXT=false
  OUTPUT_DIR="output"
  OUTPUT_FILE=""

  local args=("$@")
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    case "${args[$i]}" in
      --prompt)          PROMPT_MODE=true ;;
      --no-gherkin)      GHERKIN=false ;;
      --no-system-context) NO_SYSTEM_CONTEXT=true ;;
      --file)
        i=$((i + 1))
        FILE_PATH="${args[$i]}"
        PROMPT_MODE=false
        ;;
      --output-dir)
        i=$((i + 1))
        OUTPUT_DIR="${args[$i]}"
        ;;
    esac
    i=$((i + 1))
  done

  # Derive OUTPUT_STEM and OUTPUT_FILE
  if [[ "$PROMPT_MODE" == false && -n "$FILE_PATH" ]]; then
    local basename_no_ext
    basename_no_ext="$(basename "$FILE_PATH")"
    basename_no_ext="${basename_no_ext%.*}"
    local stem
    stem="$(echo "$basename_no_ext" | sed 's/[^a-zA-Z0-9]/_/g')"
    OUTPUT_STEM="$stem"
    if [[ "$GHERKIN" == false ]]; then
      OUTPUT_FILE="${stem}_tests_no_gherkin.md"
    else
      OUTPUT_FILE="${stem}_tests.md"
    fi
  elif [[ "$PROMPT_MODE" == false ]]; then
    # pasted content
    if [[ "$GHERKIN" == false ]]; then
      OUTPUT_FILE="pasted_content_tests_no_gherkin.md"
    else
      OUTPUT_FILE="pasted_content_tests.md"
    fi
  else
    OUTPUT_FILE=""
  fi
}

derive_sections() {
  SECTIONS_TO_LOAD=("sections/always.md")

  if [[ "$PROMPT_MODE" == true ]]; then
    SECTIONS_TO_LOAD+=("sections/prompt.md")
  else
    SECTIONS_TO_LOAD+=("sections/file.md")
  fi
}
