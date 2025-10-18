#!/usr/bin/env bash
# Run the link audit history append using ensured Python deps.
# Writes output to link_audit_history_run.txt and updates links_audit_history.csv
set -euo pipefail

# Ensure PYTHONPATH includes workspace when invoked from GitHub Actions
: "${PYTHONPATH:=}"

# Delegate to the existing helper to ensure deps and run the tool
bash .github/scripts/python-ensure-and-run.sh "import yaml, jsonschema" \
  python tools/analyze_links.py --export links_export.json --history links_audit_history.csv \
  | tee link_audit_history_run.txt
