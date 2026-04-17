#!/usr/bin/env bash
# Run all mr-review router tests.
# Usage: bash tests/mr-review/run_all.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

overall_pass=0
overall_fail=0

run_suite() {
  local name="$1" script="$2"
  echo ""
  echo -e "${BOLD}━━━ $name ━━━${NC}"
  echo ""

  set +e
  bash "$script"
  local rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    overall_pass=$((overall_pass + 1))
  else
    overall_fail=$((overall_fail + 1))
  fi
}

run_suite "Router Tests"         "$SCRIPT_DIR/test_router.sh"
run_suite "Filename Tests"       "$SCRIPT_DIR/test_filenames.sh"
run_suite "Section Skip Tests"   "$SCRIPT_DIR/test_section_skips.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $overall_fail -eq 0 ]]; then
  echo -e "${GREEN}All $overall_pass suites passed.${NC}"
  exit 0
else
  echo -e "${RED}$overall_fail suite(s) failed, $overall_pass passed.${NC}"
  exit 1
fi
