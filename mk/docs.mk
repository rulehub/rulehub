# Documentation and link checks

.PHONY: docs-serve docs-build docs-lint link-check link-check-json refs-index refs-index-all test-examples

docs-serve: ## Serve MkDocs with live reload (http://127.0.0.1:8000)
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	@if [ -f requirements-docs.txt ]; then \
	  $(PIP) install -q -r requirements-docs.txt >/dev/null; \
	else \
	  $(PIP) install -q mkdocs mkdocs-material >/dev/null; \
	fi
	$(VENV)/bin/mkdocs serve

docs-build: ## Build static MkDocs site into site/
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	@if [ -f requirements-docs.txt ]; then \
	  $(PIP) install -q -r requirements-docs.txt >/dev/null; \
	else \
	  $(PIP) install -q mkdocs mkdocs-material >/dev/null; \
	fi
	$(VENV)/bin/mkdocs build --strict

docs-lint: ## Run markdownlint, Vale, cspell (Docker toolchain or local fallback if docker missing)
	@if command -v docker >/dev/null 2>&1; then \
	  echo "[docs-lint] using docker toolchain"; \
	  if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^rulehub-doc-tools:latest$$'; then \
	    docker build -t rulehub-doc-tools:latest .github/tools; \
	  fi; \
	  docker run --rm -v "$$PWD:/workspace" -w /workspace rulehub-doc-tools:latest sh -c 'markdownlint-cli2 **/*.md; vale .; cspell "**/*.md"'; \
	else \
	  echo "[docs-lint] docker not found; using local fallback (markdownlint + cspell; skipping Vale)"; \
		  if [ ! -f package.json ]; then echo '{"name":"rulehub-docs-lint","private":true}' > package.json; fi; \
		  npm install --no-save markdownlint-cli2 cspell >/dev/null 2>&1 || { echo "[docs-lint] npm install failed" >&2; exit 2; }; \
		  npx markdownlint-cli2 \
		    "**/*.md" \
		    "!node_modules/**" "!site/**" "!dist/**" "!.venv/**" "!.github/**" "!translations/**" \
		    "!docs/references-index.md" "!docs/coverage.md" \
		    --config .markdownlint.jsonc \
		    || true; \
		  npx cspell --config cspell.json "**/*.md" "!node_modules/**" "!site/**" "!dist/**" "!.venv/**" "!.github/**" "!translations/**" || true; \
	  echo "[docs-lint] fallback complete"; \
	fi

link-check: ## Run lychee link checker (mirrors CI settings)
	@echo "[link-check] building tools image (if not present)"; \
	if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^rulehub-doc-tools:latest$$'; then \
	  docker build -t rulehub-doc-tools:latest .github/tools; \
	fi; \
	docker run --rm -v "$$PWD:/workspace" -w /workspace -e GITHUB_TOKEN=$$GITHUB_TOKEN rulehub-doc-tools:latest \
	  lychee --verbose --no-progress --max-concurrency 8 --timeout 20s \
	    --exclude-path dist --exclude-path site \
	    --exclude "https://github.com/rulehub/rulehub-charts" \
	    **/*.md

link-check-json: ## Run lychee and classify (outputs lychee.json)
	@echo "[link-check-json] building tools image (if not present)"; \
	if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^rulehub-doc-tools:latest$$'; then \
	  docker build -t rulehub-doc-tools:latest .github/tools; \
	fi; \
	set -e; \
	docker run --rm -v "$$PWD:/workspace" -w /workspace -e GITHUB_TOKEN=$$GITHUB_TOKEN rulehub-doc-tools:latest \
	  lychee --format json --no-progress --max-concurrency 8 --timeout 20s \
	    --exclude-path dist --exclude-path site \
	    --exclude "https://github.com/rulehub/rulehub-charts" \
	    **/*.md > lychee.json || true; \
	python3 .github/scripts/classify_lychee.py lychee.json || true; \
	echo "[link-check-json] report: lychee.json"

refs-index: deps ## Generate docs/references-index.md from policy metadata
	$(VENV)/bin/python tools/generate_refs_index.py || (echo "Generation failed (some policies missing links)" >&2; exit $$?)

refs-index-all: deps ## Generate references index (md+json) and fail if missing links
	$(VENV)/bin/python tools/generate_refs_index.py --format both --fail-missing-links

test-examples: deps ## Execute fenced bash/sh code blocks in docs/ marked with '# example-test'
	$(VENV)/bin/python tools/test_examples.py --docs docs
