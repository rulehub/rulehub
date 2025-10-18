#!/usr/bin/env bash
set -euo pipefail

# guardrails-aggregate.sh — run all guardrail checks used in CI
# Honors FAIL_LINK_AUDIT env ("1" to enforce link audit failures)

# Ensure Python deps on demand; prefer prebuilt venv if available
if [ -x .github/scripts/python-venv-install.sh ]; then
  bash .github/scripts/python-venv-install.sh
fi

FAIL_LINK_AUDIT="${FAIL_LINK_AUDIT:-0}"

# Generic-only test guardrail
bash .github/scripts/python-ensure-and-run.sh "import yaml, jsonschema" python tools/enforce_no_generic_only_tests.py
# Metadata paths guardrail
bash .github/scripts/python-ensure-and-run.sh "import yaml, jsonschema" python tools/guardrail_metadata_paths.py
# Test pairs guardrail
bash .github/scripts/python-ensure-and-run.sh "import yaml" python tools/enforce_policy_test_pairs.py
# Schema validation
bash .github/scripts/python-ensure-and-run.sh "import jsonschema" python tools/validate_metadata_schema.py
# Link normalization (non-fatal)
bash .github/scripts/python-ensure-and-run.sh "import yaml" python tools/normalize_links.py --check --eli || echo "[guardrails] link-normalize-check non-fatal issues"

# Link audit (enforced only when FAIL_LINK_AUDIT=1)
if [ "${FAIL_LINK_AUDIT}" = "1" ]; then
  bash .github/scripts/python-ensure-and-run.sh "import yaml, jsonschema" python tools/analyze_links.py --export links_export.json --json links_audit_report.json >/dev/null
  python tools/compare_links_baseline.py || exit 1
else
  bash .github/scripts/python-ensure-and-run.sh "import yaml, jsonschema" python tools/analyze_links.py --export links_export.json --json links_audit_report.json >/dev/null || true
  python tools/compare_links_baseline.py || echo "[guardrails] link-audit non-fatal"
fi

echo "[guardrails] complete"
