#!/usr/bin/env bash
# helpers/flag_parser.sh — Standalone flag parser for confluence-test-gen router tests.
# Mirrors the Step 0 logic in skills/confluence-test-gen/sections/always.md.
# Source this file, then call parse_flags "$@" and derive_sections.

parse_flags() {
  # Reset all variables
  CONFLUENCE_URL=""
  CREATE=false
  GHERKIN=true
  BLACKBOX=false
  NO_CLARIFY=false
  NEG_ONLY=false
  INCLUDE_CHILDREN=false
  NO_TESTDATA=false
  TESTDATA_ONLY=false
  OUTPUT_DIR="output"
  SLUG="test_page"  # placeholder; real slug derived from page title at runtime

  local args=("$@")
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    case "${args[$i]}" in
      --create)           CREATE=true ;;
      --no-gherkin)       GHERKIN=false ;;
      --blackbox)         BLACKBOX=true ;;
      --no-clarify)       NO_CLARIFY=true ;;
      --neg-only)         NEG_ONLY=true ;;
      --include-children) INCLUDE_CHILDREN=true ;;
      --no-testdata)      NO_TESTDATA=true ;;
      --testdata-only)    TESTDATA_ONLY=true ;;
      --output-dir)
        i=$((i + 1))
        OUTPUT_DIR="${args[$i]}"
        ;;
      http*)              CONFLUENCE_URL="${args[$i]}" ;;
    esac
    i=$((i + 1))
  done

  # Implied flags
  [[ "$NEG_ONLY"      == true ]] && NO_CLARIFY=true
  [[ "$TESTDATA_ONLY" == true ]] && NO_CLARIFY=true

  # Derive OUTPUT_FILE (test document)
  local base="confluence-${SLUG}_tests"
  [[ "$BLACKBOX"    == true  ]] && base="${base}_blackbox"
  [[ "$NEG_ONLY"    == true  ]] && base="${base}_neg"
  [[ "$GHERKIN"     == false ]] && base="${base}_no_gherkin"
  OUTPUT_FILE="${base}.md"

  # Exception: --no-clarify only (not blackbox, not neg-only, gherkin=true) → no suffix
  if [[ "$NO_CLARIFY" == true && "$BLACKBOX" == false && "$NEG_ONLY" == false && "$GHERKIN" == true ]]; then
    OUTPUT_FILE="confluence-${SLUG}_tests.md"
  fi

  # TESTDATA_FILE
  TESTDATA_FILE="confluence-${SLUG}_testdata.md"
}

derive_sections() {
  SECTIONS_TO_LOAD=(
    "sections/always.md"
    "sections/fetch.md"
    "sections/format.md"
    "sections/sections-neg.md"
    "sections/sections-meta.md"
    "sections/write.md"
  )

  # Conditional: sections-happy.md only when NEG_ONLY=false
  if [[ "$NEG_ONLY"    == false ]]; then SECTIONS_TO_LOAD+=("sections/sections-happy.md"); fi
  # Conditional: testdata.md only when NO_TESTDATA=false (and not testdata-only skip — testdata.md
  # has its own SKIP_IF guard, but the router still loads it when NO_TESTDATA=false)
  if [[ "$NO_TESTDATA" == false ]]; then SECTIONS_TO_LOAD+=("sections/testdata.md"); fi
}
