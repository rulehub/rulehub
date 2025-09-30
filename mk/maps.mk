# Compliance maps utilities

.PHONY: maps-dupes-check maps-dupes-fix sort-maps charts-drift-compare

maps-dupes-check:
	@echo "Checking duplicate policies in compliance maps"
	python3 tools/fix_compliance_map_dupes.py --check

maps-dupes-fix:
	@echo "Fixing duplicate policies in compliance maps"
	python3 tools/fix_compliance_map_dupes.py --fix

sort-maps: deps ## Sort compliance map policy lists alphabetically
	$(VENV)/bin/python tools/sort_compliance_policies.py

charts-drift-compare: deps ## Compare dist/index.json vs rulehub-charts manifests (set CHARTS_DIR)
	@if [ -z "$(CHARTS_DIR)" ]; then echo "Usage: make charts-drift-compare CHARTS_DIR=../rulehub-charts/files"; exit 2; fi
	$(VENV)/bin/python tools/compare_charts_policies.py --charts-dir $(CHARTS_DIR)
