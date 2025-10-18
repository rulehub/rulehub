#!/usr/bin/env bash
set -euo pipefail

# run-link-audit.sh
# Runs link audit inside CI image with pre-baked Python env (or host fallback if used outside container)
# Honors existing helper .github/scripts/python-ensure-and-run.sh when present.

# If a virtualenv exists, activate it; otherwise, rely on python-ensure-and-run.sh to install minimal deps.
if [[ -d .venv ]]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

if [[ -x .github/scripts/python-ensure-and-run.sh ]]; then
  bash .github/scripts/python-ensure-and-run.sh "import yaml, jsonschema" \
    python tools/analyze_links.py --export links_export.json --json links_audit_report.json
else
  python tools/analyze_links.py --export links_export.json --json links_audit_report.json
fi

# Compare against baseline; honors FAIL_LINK_AUDIT=1 to fail on drift
python tools/compare_links_baseline.py | tee link_audit_output.txt
