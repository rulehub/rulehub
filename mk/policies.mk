# Policy-related helpers and maintenance

.PHONY: opa-quick-check refactor-policies repair-tests prune-generic-tests policy-maintenance normalize-metadata-paths granular-tests deny-usage-scan

opa-quick-check: ## Run OPA syntax/type check and grep for disallowed boolean patterns

	if grep -R -nF -e "(not " -e "and not" -e "not (" policies >/dev/null; then \
	  grep -R -nF -e "(not " -e "and not" -e "not (" policies || true; \
	  echo "Found disallowed negation/composite patterns" >&2; \
	  exit 2; \
	else \
	  echo "None"; \
	fi
	@echo "[scan] ' not in {':"; \
	if grep -R -nE ' not in \\{' policies >/dev/null; then \
	  grep -R -nE ' not in \\{' policies || true; \
	  exit 3; \
	else \
	  echo "None"; \
	fi

refactor-policies: deps ## Refactor disallowed patterns & regenerate tests (dry-run unless APPLY=1)
	CMD="$(VENV)/bin/python tools/refactor_policies.py"; \
	if [ "$(APPLY)" = "1" ]; then CMD="$$CMD --apply"; fi; \
	echo "Running: $$CMD"; eval $$CMD

repair-tests: deps ## Repair corrupted test files to standard evidence pattern
	$(VENV)/bin/python tools/repair_tests.py

prune-generic-tests: deps ## Remove generic-only deny tests when evidence tests exist
	$(VENV)/bin/python tools/prune_generic_tests.py

policy-maintenance: deps ## Refactor + repair + prune + normalize metadata paths (APPLY=1 to write refactors)
	$(MAKE) refactor-policies $(if $(APPLY),APPLY=$(APPLY))
	$(MAKE) repair-tests
	$(MAKE) prune-generic-tests
	$(MAKE) normalize-metadata-paths
	$(MAKE) link-normalize $(if $(APPLY),,)

normalize-metadata-paths: deps ## Normalize empty path lines to 'path: []'
	$(VENV)/bin/python tools/normalize_metadata_paths.py --apply

# Usage: make granular-tests [APPLY=1] [LIMIT=N]
#   APPLY=1  -> write changes
#   LIMIT=N  -> limit number of policies processed
granular-tests: deps
	@echo "[granular-tests] scanning multi-rule policies";
	CMD="$(VENV)/bin/python tools/generate_granular_policy_tests.py"; \
	if [ -n "$(LIMIT)" ]; then CMD="$$CMD --limit $(LIMIT)"; fi; \
	if [ "$(APPLY)" = "1" ]; then CMD="$$CMD --apply"; fi; \
	echo "Running: $$CMD"; eval $$CMD

deny-usage-scan: ## Fail if any disallowed 'violation[' usage remains in templates/ or addons/
	@python tools/deny_usage_scan.py
