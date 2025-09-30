# Validation targets

.PHONY: validate validate-strict validate-maps validate-metadata-schema workspace-clean

validate: deps
	$(VENV)/bin/python tools/validate_metadata.py

validate-strict: deps
	STRICT_EMPTY_PATHS=1 $(VENV)/bin/python tools/validate_metadata.py

validate-maps: deps
	$(VENV)/bin/python tools/validate_compliance_maps.py

validate-metadata-schema: deps ## Validate metadata.yaml files against JSON Schema
	$(VENV)/bin/python tools/validate_metadata_schema.py

workspace-clean: ## Ensure git working tree clean and dist/ contains only expected artifacts
	@echo "[workspace-clean] checking git status"; \
	if [ -n "$(shell git status --porcelain)" ]; then \
	  echo "[workspace-clean] Git working tree is dirty:" >&2; \
	  git status --porcelain >&2; \
	  exit 2; \
	else \
	  echo "[workspace-clean] git clean"; \
	fi; \
	ALLOWED="opa-bundle.tar.gz opa-bundle.manifest.json opa-bundle.provenance.json opa-bundle.sbom.cdx.json opa-bundle.sbom.spdx.json opa-bundle.tar.gz.sig opa-bundle.tar.gz.pem dist.manifest.json policy-test-coverage.json coverage.json coverage_by_policy.json index.json link_audit.md coverage.html policies-index.json policies.csv references-index.json policy-test-priorities.md policy_coverage_audit.json policy_coverage_audit.md policy_coverage_audit_trimmed.md policy_coverage_audit.csv policy_dependency_graph.json compliance_maps_export.csv"; \
	if [ ! -d dist ]; then echo "[workspace-clean] dist/ absent (OK)"; exit 0; fi; \
	UNEXPECTED=0; \
	for f in dist/*; do \
	  [ -f "$$f" ] || continue; \
	  base=$$(basename "$$f"); \
	  echo " $$ALLOWED " | grep -F " $$base " >/dev/null 2>&1 || { echo "[workspace-clean] unexpected dist file: $$base" >&2; UNEXPECTED=1; }; \
	done; \
	if [ $$UNEXPECTED -ne 0 ]; then \
	  echo "[workspace-clean] FAIL (unexpected files listed above)" >&2; exit 3; \
	else \
	  echo "[workspace-clean] OK"; \
	fi
