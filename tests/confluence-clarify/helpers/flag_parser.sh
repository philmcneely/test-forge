#!/usr/bin/env bash
# tests/confluence-clarify/helpers/flag_parser.sh
# Mirrors Step 0 logic in skills/confluence-clarify/sections/always.md.

parse_flags() {
  CONFLUENCE_URL=""
  CREATE=false
  OUTPUT_DIR="output"
  SLUG="test_page"

  local args=("$@")
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    case "${args[$i]}" in
      --create)   CREATE=true ;;
      --output-dir)
        i=$((i + 1))
        OUTPUT_DIR="${args[$i]}"
        ;;
      http*)      CONFLUENCE_URL="${args[$i]}" ;;
    esac
    i=$((i + 1))
  done

  # Derive SLUG from URL (last path segment, simplified)
  if [[ -n "$CONFLUENCE_URL" ]]; then
    local raw_slug
    raw_slug="$(basename "$CONFLUENCE_URL" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | cut -c1-60)"
    SLUG="${raw_slug:-test_page}"
  fi

  OUTPUT_FILE="confluence-${SLUG}_clarify.md"
}

derive_sections() {
  SECTIONS_TO_LOAD=(
    "sections/always.md"
    "sections/fetch.md"
    "sections/generate.md"
    "sections/write.md"
  )
}
