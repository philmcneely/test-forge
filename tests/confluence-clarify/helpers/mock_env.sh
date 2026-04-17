#!/usr/bin/env bash
# Shared mock environment for jira-test-gen router tests.
# No real Jira / Zephyr credentials required.

export JIRA_URL="https://fake.jira.example.com"
export JIRA_USERNAME="test@example.com"
export JIRA_API_TOKEN="fake-token-abc123"
export ZEPHYR_API_TOKEN="fake-zephyr-token"
export ZEPHYR_BASE_URL="https://fake.zephyrscale.example.com/v2"

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo -e "${GREEN}PASS${NC}  $label"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  $label"
    echo "       expected: $expected"
    echo "       actual:   $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo -e "${GREEN}PASS${NC}  $label"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  $label"
    echo "       expected to find: $needle"
    echo "       in: $haystack"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local label="$1" needle="$2" haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo -e "${GREEN}PASS${NC}  $label"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}  $label"
    echo "       expected NOT to find: $needle"
    echo "       in: $haystack"
    FAIL=$((FAIL + 1))
  fi
}

print_summary() {
  echo ""
  echo "─────────────────────────────────────────────"
  echo -e "Results: ${GREEN}$PASS passed${NC}  ${RED}$FAIL failed${NC}"
  [[ $FAIL -eq 0 ]] && exit 0 || exit 1
}
