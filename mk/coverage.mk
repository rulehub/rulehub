# Coverage and catalog

.PHONY: coverage catalog perf-coverage metrics-capture

coverage: deps ## Generate coverage docs + JSON artifacts (coverage, policies, plugin index)
	$(VENV)/bin/python tools/coverage_map.py

# 'catalog' is an alias that ensures the coverage artifacts exist (particularly dist/index.json)
catalog: coverage
	@echo "Catalog: dist/index.json"

perf-coverage: deps ## Run performance check for coverage generation (set COVERAGE_MAX_SECONDS)
	$(VENV)/bin/python tools/perf_check_coverage.py

metrics-capture: deps ## Generate dist/release-metrics.json release telemetry snapshot
	$(VENV)/bin/python tools/generate_release_metrics.py
