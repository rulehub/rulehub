# Tests (Kyverno, Gatekeeper, tools) and thresholds/guardrails

.PHONY: test-kyverno test-gatekeeper test test-strict test-tools policy-test-coverage policy-test-threshold policy-test-pairs guardrail-generic-only guardrail-metadata-paths guardrails quick full

test-kyverno:
	@bash tools/kyverno_test.sh

test-gatekeeper:
	@command -v opa >/dev/null 2>&1 || { echo "OPA not found. See https://www.openpolicyagent.org/docs/latest/#running-opa"; exit 127; }
	opa test tests/gatekeeper/policies tests/gatekeeper/tests -v

test: test-kyverno test-gatekeeper

test-strict: deps ## Fail if multi-deny policies lack aggregate test_<id>_denies_when_any_violation
	@# Ensure latest sources installed
	$(VENV)/bin/python tools/enforce_strict_tests.py

test-tools:
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(VENV)/bin/python -m pip install -U pip >/dev/null
	$(PIP) install -r requirements.txt >/dev/null
	@if [ -f requirements-dev.lock ]; then \
	  $(PIP) install -r requirements-dev.lock >/dev/null; \
	else \
	  $(PIP) install -r requirements-dev.txt >/dev/null; \
	fi
	$(VENV)/bin/pytest -q tests/tools

policy-test-coverage: deps ## Generate dist/policy-test-coverage.json summary
	$(VENV)/bin/python tools/policy_test_coverage.py

policy-test-threshold: deps ## Enforce quality thresholds (dual-direction 100%, no multi-rule gaps)
	@# Run coverage first to ensure JSON is fresh
	$(VENV)/bin/python tools/policy_test_coverage.py >/dev/null
	$(VENV)/bin/python tools/enforce_policy_test_thresholds.py

policy-test-pairs: deps ## Enforce policy/test file pairing + metadata path completeness
	$(VENV)/bin/python tools/enforce_policy_test_pairs.py

guardrail-generic-only: deps ## Fail if deny tests rely only on control toggles
	$(VENV)/bin/python tools/enforce_no_generic_only_tests.py

guardrail-metadata-paths: deps ## Fail on bare 'path:' lines (STRICT_EMPTY_PATHS=1 forbids placeholders)
	$(VENV)/bin/python tools/guardrail_metadata_paths.py

guardrails: deps ## Run all guardrail scripts (incl. schema, link audit). Set FAIL_LINK_AUDIT=1 to fail on findings.
	@set -e; echo "[guardrails] running generic-only test guardrail"; \
	  $(VENV)/bin/python tools/enforce_no_generic_only_tests.py; \
	  echo "[guardrails] generic-only OK"
	@set -e; echo "[guardrails] running metadata paths guardrail"; \
	  $(VENV)/bin/python tools/guardrail_metadata_paths.py; \
	  echo "[guardrails] metadata paths OK"
	@set -e; echo "[guardrails] enforcing policy test pairs"; \
	  $(VENV)/bin/python tools/enforce_policy_test_pairs.py; \
	  echo "[guardrails] test pairs OK"
	@set -e; echo "[guardrails] validating metadata schema"; \
	  $(VENV)/bin/python tools/validate_metadata_schema.py; \
	  echo "[guardrails] schema OK"
	@echo "[guardrails] link normalization check"; \
	  $(VENV)/bin/python tools/normalize_links.py --check --eli || echo "[guardrails] link-normalize-check non-fatal issues"
	@echo "[guardrails] link audit"; \
	  if [ "$(FAIL_LINK_AUDIT)" = "1" ]; then \
	    $(MAKE) link-audit FAIL_LINK_AUDIT=1; \
	  else \
	    $(MAKE) link-audit || echo "[guardrails] link-audit non-fatal"; \
	  fi; \
	  echo "[guardrails] link audit complete"
	@echo "[guardrails] complete"

quick: ## Fast inner loop (Python lint + Gatekeeper tests)
	$(MAKE) lint-py
	$(MAKE) test-gatekeeper

full: verify-all ## Alias for verify-all
