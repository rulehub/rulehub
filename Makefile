# Prefer python3, but fall back to python (some distros only ship `python` as Python 3)
# Using a subshell to handle the OR logic reliably across POSIX sh.
PY ?= $(shell sh -c 'command -v python3 >/dev/null 2>&1 && printf python3 || printf python')
VENV := .venv
PIP := $(VENV)/bin/pip

.PHONY: help
help:
	@echo "Targets:"
	@echo "  setup-dev              Create venv and install dev deps"
	@echo "  deps                   Install runtime deps (requirements.txt) into venv"
	@echo "  lock                   Compile pinned requirements.lock from requirements.txt"
	@echo "  lock-dev               Compile pinned requirements-dev.lock from requirements-dev.txt"
	@echo "  pre-commit-install     Install git hooks"
	@echo "  validate               Validate policy metadata (schema + paths)"
	@echo "  validate-strict        Validate metadata and fail on empty path arrays"
	@echo "  validate-maps          Validate compliance maps schema"
	@echo "  validate-metadata-schema Validate policy metadata against JSON Schema"
	@echo "  coverage               Generate docs/coverage.md and dist/* (HTML+JSON)"
	@echo "  catalog                Generate dist/index.json for Backstage plugin"
	@echo "  maps-dupes-check       Check duplicate policies in compliance maps"
	@echo "  maps-dupes-fix         Auto-fix duplicate policies in compliance maps"
	@echo "  sort-maps              Sort compliance map policy lists alphabetically"
	@echo "  test-kyverno           Run kyverno tests"
	@echo "  test-gatekeeper        Run Gatekeeper (OPA) unit tests"
	@echo "  test                   Run all policy framework tests"
	@echo "  test-strict            Enforce aggregate any_violation tests for multi-deny policies"
	@echo "  test-tools             Run tooling tests"
	@echo "  lint-yaml              Run Spectral (Stoplight)"
	@echo "  lint-py                Ruff check for tools/*.py"
	@echo "  format-py              Ruff format for tools/*.py"
	@echo "  typecheck              Run mypy on tools/*.py"
	@echo "  audit-links            Audit metadata links"
	@echo "  link-normalize         Normalize metadata link formatting (in-place)"
	@echo "  link-normalize-check   Fail if link normalization would change files"
	@echo "  link-audit            Heuristic link audit & discrepancy report"
	@echo "  link-audit-weekly     Aggregate links_audit_history*.csv into weekly summary CSV"
	@echo "  link-audit-diff       Compare link audit report vs baseline (set FAIL_LINK_AUDIT=1 to fail on drift)"
	@echo "  link-audit-md         Generate markdown link audit report to dist/link_audit.md"
	@echo "  deps-diff              List new Python dependencies since previous release"
	@echo "  export-links           Export policies links to JSON"
	@echo "  opa-bundle             Build OPA bundle (dist/opa-bundle.tar.gz)"
	@echo "  opa-bundle-manifest    Generate manifest JSON for bundle"
	@echo "  opa-bundle-provenance  Generate simplified SLSA provenance attestation JSON"
	@echo "  opa-bundle-all         Bundle + manifest + SBOM + provenance"
	@echo "  oras-publish           Publish OPA bundle to OCI (needs IMAGE,TAG)"
	@echo "  changelog-fragment     Generate CHANGELOG fragment (BASE=vX.Y.Z TARGET=main VERSION=X.Y.Z)"
	@echo "  map-changelog          Generate compliance maps changelog fragment (SINCE=vX.Y.Z)"
	@echo "  zip-backup             Create zip archive of git-tracked files"
	@echo "  sbom-opa-bundle        Generate SBOM (Syft) for dist/opa-bundle.tar.gz"
	@echo "  sign-opa-bundle        Cosign sign-blob for dist/opa-bundle.tar.gz (keyless by default)"
	@echo "  verify-opa-bundle      Verify Cosign signature for dist/opa-bundle.tar.gz"
	@echo "  verify-bundle          Verify bundle integrity (manifest + hashes + structure)"
	@echo "  dist-manifest          Generate manifest for dist/ artifact inventory"
	@echo "  verify-dist-manifest   Verify dist/ files vs dist manifest"
	@echo "  verify-all-integrity   Aggregate integrity checks (bundle + dist manifests + cross checks)"
	@echo "  sign-oci               Cosign sign pushed OCI artifact (needs IMAGE,TAG)"
	@echo "  docs-serve             Run MkDocs live-reload dev server"
	@echo "  docs-build             Build static MkDocs site into site/"
	@echo "  refs-index             Generate aggregated references-index.md (from metadata)"
	@echo "  refs-index-all         Generate references (md+json, fail on missing links)"
	@echo "  act-list               List GitHub Actions jobs (act -l)"
	@echo "  act-python-tests       Run python-tests workflow (single py 3.11)"
	@echo "  act-python-tests-all   Run python-tests workflow (all matrix)"
	@echo "  act-opa-bundle         Run opa-bundle-publish (SKIP_SUPPLYCHAIN=1)"
	@echo "  act-run                Generic act runner (WF=... EVENT=push JOB=name)"
	@echo "  act-all-push           Run all workflows with event 'push' sequentially"
	@echo "  opa-quick-check        Fast static Rego parse/type + pattern scan"
	@echo "  opa-fmt-fix            Auto-format all Rego policies (opa fmt -w)"
	@echo "  deny-usage-scan        Check absence of disallowed 'violation[' rule tokens"
	@echo "  policy-test-coverage   Compute basic Gatekeeper policy test coverage metric"
	@echo "  granular-tests         Generate per-rule deny tests (dry-run by default)"
	@echo "  policy-test-threshold  Enforce dual-direction == 100% & no multi-rule gaps (configurable)"
	@echo "  policy-test-pairs      Enforce each policy.rego has policy_test.rego and metadata paths include both"
	@echo "  guardrail-generic-only  Guardrail: forbid generic-control-only deny tests"
	@echo "  guardrail-metadata-paths Guardrail: forbid bare 'path:' (STRICT_EMPTY_PATHS=1 also forbids 'path: []')"
	@echo "  refactor-policies        Refactor disallowed 'not input.xxx' to '== false' + regenerate tests (apply)"
	@echo "  repair-tests             Repair corrupted test files to standard pattern"
	@echo "  prune-generic-tests      Remove generic-only deny tests when evidence-based tests exist"
	@echo "  policy-maintenance       Run end-to-end refactor + repair + prune + normalization (dry-run unless APPLY=1)"
	@echo "  guardrails             Run all guardrail scripts (tests, paths, schema, links)"
	@echo "  normalize-metadata-paths Normalize metadata 'path:' -> 'path: []' placeholders"
	@echo "  bundle-deterministic   Build bundle twice and compare SHA256 digest"
	@echo "  artifacts-verify       Verify presence of release artifacts (bundle, sbom, sig, manifest, dep graph)"
	@echo "  release-check          Aggregate pre-release gates (lint, tests, thresholds, guardrails, maps, coverage, links)"
	@echo "  docs-lint              Run markdownlint, Vale, cspell over docs + README"
	@echo "  link-check             Run lychee link checker (same args as CI)"
	@echo "  link-check-json        Run lychee producing JSON + classify (local)"
	@echo "  verify-all             Aggregate: lint-all + tests + coverage + link-check"
	@echo "  lint-all               Run YAML, Python, docs/style, deny usage scan"
	@echo "  quick                  Fast inner loop (lint-py + test-gatekeeper)"
	@echo "  full                   Alias for verify-all"
	@echo "  charts-drift-compare   Compare dist/index.json vs chart manifests (CHARTS_DIR=../rulehub-charts/files)"
	@echo "  perf-coverage          Run coverage_map.py performance check (thresholds)"
	@echo "  workspace-clean        Fail if git dirty or unexpected files present in dist/"
	@echo "  metrics-capture        Generate dist/release-metrics.json (policy/map counts)"
	@echo "  test-examples          Execute whitelisted bash/sh examples from docs (marker: # example-test)"
	@echo "  security-secrets       Run lightweight local secret scan (no Docker)"
	@echo "  security-checkov       Run Checkov IaC scan locally (Kubernetes framework)"

# Include modular makefiles (order matters only for variable defaults)
include mk/env.mk
include mk/act.mk
include mk/tests.mk
include mk/policies.mk
include mk/coverage.mk
include mk/lint.mk
include mk/bundle.mk
include mk/links.mk
include mk/docs.mk
include mk/maps.mk
include mk/validate.mk
include mk/release.mk

.PHONY: security-secrets
security-secrets: ## Run lightweight local secret scan (no Docker)
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	$(VENV)/bin/python tools/secret_scan.py

.PHONY: security-checkov
security-checkov: ## Run Checkov IaC scan locally (Kubernetes framework)
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	# Try a moderately recent Checkov; fall back to latest if resolver issues
	@($(PIP) install 'checkov~=3.2' >/dev/null 2>&1 || $(PIP) install checkov >/dev/null)
	$(VENV)/bin/checkov -d . --framework kubernetes \
	  --skip-path tests/kyverno --skip-path tests/gatekeeper
