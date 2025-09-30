# Links tooling and exports

.PHONY: audit-links link-normalize link-normalize-check link-audit link-audit-weekly link-audit-md link-audit-diff export-links deps-diff

audit-links: deps ## Audit quality of links (duplicates, http, version hints)
	$(VENV)/bin/python tools/audit_links.py --summary

link-normalize: deps ## Normalize links (indentation, dedupe, CELEX) in-place
	$(VENV)/bin/python tools/normalize_links.py --write --eli

link-normalize-check: deps ## Check link normalization (no changes required)
	$(VENV)/bin/python tools/normalize_links.py --check --eli

link-audit: deps ## Heuristic link audit & metadata/export discrepancy report
	$(VENV)/bin/python tools/analyze_links.py --export links_export.json

link-audit-weekly: deps ## Aggregate links_audit_history*.csv into weekly metrics CSV (links_audit_weekly.csv)
	$(VENV)/bin/python tools/aggregate_link_history.py

link-audit-md: deps ## Heuristic link audit in markdown (writes dist/link_audit.md)
	@mkdir -p dist
	OUTPUT_FORMAT=markdown $(VENV)/bin/python tools/analyze_links.py --export links_export.json > dist/link_audit.md
	@echo "Wrote dist/link_audit.md"

link-audit-diff: deps ## Compare current link audit report vs baseline (non-fatal unless FAIL_LINK_AUDIT=1)
	@if [ ! -f links_audit_report.json ]; then \
	  echo "[link-audit-diff] generating fresh links_audit_report.json"; \
	  $(VENV)/bin/python tools/analyze_links.py --export links_export.json --json links_audit_report.json >/dev/null; \
	else \
	  echo "[link-audit-diff] using existing links_audit_report.json"; \
	fi; \
	$(VENV)/bin/python tools/compare_links_baseline.py || true

export-links: deps ## Export id, name, links arrays into links_export.json
	$(VENV)/bin/python tools/export_links.py links_export.json
	@echo "Wrote links_export.json"

deps-diff: ## List new Python dependencies between last two release tags (or last two commits touching lock files)
	python3 tools/diff_new_dependencies.py
