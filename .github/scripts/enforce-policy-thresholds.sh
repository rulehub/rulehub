#!/usr/bin/env bash
set -euo pipefail

# Run policy test coverage computation + threshold enforcement + optional summary.
# Usage: enforce-policy-thresholds.sh [--no-summary]

no_summary=0
while [ $# -gt 0 ]; do
  case "$1" in
    --no-summary) no_summary=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Ensure venv / deps via existing helper if available
if [ -x .github/scripts/python-venv-install.sh ]; then
  bash .github/scripts/python-venv-install.sh
fi

cov_cmd=(bash .github/scripts/python-ensure-and-run.sh "import json" python tools/policy_test_coverage.py)
thr_cmd=(bash .github/scripts/python-ensure-and-run.sh "import json" python tools/enforce_policy_test_thresholds.py)

"${cov_cmd[@]}" >/dev/null
"${thr_cmd[@]}"

if [ $no_summary -eq 0 ] && [ -n "${GITHUB_STEP_SUMMARY:-}" ] && [ -f dist/policy-test-coverage.json ]; then
  dual=$(jq -r '.dual_direction.percent' dist/policy-test-coverage.json 2>/dev/null || echo "?")
  inadequate=$(jq -r '.multi_rule.count_inadequate' dist/policy-test-coverage.json 2>/dev/null || echo "?")
  {
    echo "### Policy Test Threshold"
    echo "Dual-direction: ${dual}%"
    echo "Multi-rule inadequacies: ${inadequate}"
    if [ "${inadequate}" != "0" ] && [ "${inadequate}" != "?" ]; then
      echo
      echo "Failures (first 10):"
      jq -r '.multi_rule.list_inadequate[:10][] | "- \(.policy) deny_rules=\(.deny_rules) tests=\(.deny_test_assertions)"' dist/policy-test-coverage.json 2>/dev/null || true
    fi
  } >> "$GITHUB_STEP_SUMMARY"
fi

echo "[enforce-policy-thresholds] Done" >&2
