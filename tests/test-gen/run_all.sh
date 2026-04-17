#!/usr/bin/env bash
# tests/test-gen/run_all.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
overall_pass=0; overall_fail=0

run_suite() {
  local script="$1"
  if bash "$script"; then
    overall_pass=$((overall_pass + 1))
  else
    overall_fail=$((overall_fail + 1))
  fi
  echo ""
}

run_suite "$SCRIPT_DIR/test_router.sh"
run_suite "$SCRIPT_DIR/test_filenames.sh"
run_suite "$SCRIPT_DIR/test_section_skips.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $overall_fail -eq 0 ]]; then
  echo -e "${GREEN}All $overall_pass suites passed.${NC}"
  exit 0
else
  echo -e "${RED}$overall_fail suite(s) failed.${NC}"
  exit 1
fi
