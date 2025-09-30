#!/usr/bin/env bash
set -euo pipefail

echo "[health] Toolchain versions"
for cmd in python3 kubectl helm kyverno opa oras cosign syft yq jq; do
  if command -v "$cmd" >/dev/null 2>&1; then
    case "$cmd" in
      python3) echo "python3: $(python3 --version 2>&1)";;
      kubectl) echo "kubectl: $(kubectl version --client --short 2>/dev/null || true)";;
      helm) echo "helm: $(helm version --short 2>/dev/null || true)";;
      kyverno) echo "kyverno: $(kyverno version 2>/dev/null | head -n1 || true)";;
      opa) echo "opa: $(opa version 2>/dev/null | sed -n 's/^Version: //p' | head -n1 || true)";;
      oras) echo "oras: $(oras version 2>/dev/null | head -n1 || true)";;
      cosign) echo "cosign: $(cosign version 2>/dev/null | sed -n 's/^Version: //p' | head -n1 || true)";;
      syft) echo "syft: $(syft version 2>/dev/null | head -n1 || true)";;
      yq) echo "yq: $(yq --version 2>/dev/null || true)";;
      jq) echo "jq: $(jq --version 2>/dev/null || true)";;
    esac
  else
    echo "[missing] $cmd"
  fi
done

# Basic repo checks
printf '\n[health] Repo checks\n'
# Count policies and maps
policies_cnt=$(find policies -type f -name metadata.yaml | wc -l | tr -d ' ' || echo 0)
maps_cnt=$(find compliance/maps -type f -name '*.yml' | wc -l | tr -d ' ' || echo 0)
echo "policies metadata files: $policies_cnt"
echo "compliance maps: $maps_cnt"

# Quick schema validate (soft fail)
if command -v python3 >/dev/null 2>&1; then
  python3 tools/validate_metadata.py >/dev/null 2>&1 && echo "metadata validate: OK" || echo "metadata validate: FAIL"
  python3 tools/validate_compliance_maps.py >/dev/null 2>&1 && echo "maps validate: OK" || echo "maps validate: FAIL"
fi

echo "[health] Done"
