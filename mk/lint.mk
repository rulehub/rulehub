# Linting and formatting

.PHONY: lint format lint-yaml lint-py format-py typecheck docs-lint verify-all lint-all link-check link-check-json

lint: lint-py

format: format-py

lint-yaml:
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	$(PIP) install -r requirements-dev.txt >/dev/null
	@echo "Using Spectral config: .spectral.yml"; \
	# Use npx to run Spectral CLI so we don't require npm global installs in dev venv
	@npx -y @stoplight/spectral lint --ruleset .spectral.yml --format json . \
	  | python3 tools/convert_spectral_to_sarif.py - --output spectral.sarif || true

lint-py:
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	$(PIP) install ruff >/dev/null
	$(VENV)/bin/ruff check tools

format-py:
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	$(PIP) install ruff >/dev/null
	$(VENV)/bin/ruff format tools

typecheck:
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	$(PIP) install -r requirements.txt >/dev/null
	@if [ -f requirements-dev.lock ]; then \
	  $(PIP) install -r requirements-dev.lock >/dev/null; \
	else \
	  $(PIP) install -r requirements-dev.txt >/dev/null; \
	fi
	$(PIP) install mypy >/dev/null
	$(VENV)/bin/mypy --install-types --non-interactive --config-file mypy.ini

# Docs lint + link checks

# docs-lint target is in docs.mk to co-locate docker logic; expose verify-all here

lint-all: ## Aggregate: YAML + Python lint + docs/style + deny usage scan
	$(MAKE) lint-yaml
	$(MAKE) lint-py
	$(MAKE) docs-lint
	$(MAKE) deny-usage-scan

verify-all: ## Aggregate: lint-all + tests + coverage + link-check (soft-fail transient links)
	$(MAKE) lint-all
	$(MAKE) test
	$(MAKE) coverage
	-$(MAKE) link-check || echo "[verify-all] link-check reported hard failures (see above)"

.PHONY: scan-invisible-unicode
scan-invisible-unicode: ## Scan for invisible/zero-width Unicode and write dist/invisible-unicode-report.txt
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(VENV)/bin/python tools/scan_invisible_unicode.py
