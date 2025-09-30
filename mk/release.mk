# Release aggregation and changelogs

.ONESHELL: release-check

.PHONY: release-check changelog-fragment map-changelog

release-check: ## Aggregate pre-release quality gates (lint, tests, thresholds, guardrails, maps, coverage, links) with summary table
	@echo "[release-check] starting"
	overall=0
	mandatory_steps="lint-all test guardrails validate-maps policy-test-threshold coverage"
	echo ""
	printf "%-24s | %s\n" "Step" "Status"
	echo "--------------------------|--------"
	for s in $$mandatory_steps; do
	  if $(MAKE) -s $$s; then st=OK; else st=FAIL; overall=1; fi
	  printf "%-24s | %s\n" "$$s" "$$st"
	done
	# Soft (non-fatal) step: link-check
	if $(MAKE) -s link-check; then st=OK; else st=FAIL; fi
	printf "%-24s | %s (soft)\n" "link-check" "$$st"
	echo "--------------------------|--------"
	if [ "$$overall" != "0" ]; then
	  echo "[release-check] SUMMARY: FAIL"; exit 2
	else
	  echo "[release-check] SUMMARY: OK"
	fi

changelog-fragment: ## Generate CHANGELOG fragment between BASE tag and TARGET ref
	@if [ -z "$(BASE)" ]; then echo "Usage: make changelog-fragment BASE=vX.Y.Z [TARGET=main] [VERSION=X.Y.Z]"; exit 2; fi
	@TARGET_REF=$(if $(TARGET),$(TARGET),main); \
	CMD="python3 tools/generate_changelog_fragment.py --base-tag $(BASE) --target $$TARGET_REF"; \
	if [ -n "$(VERSION)" ]; then CMD="$$CMD --version $(VERSION)"; fi; \
	echo "Running: $$CMD" >&2; eval $$CMD

map-changelog: ## Generate compliance maps changelog fragment (SINCE tag optional)
	@SINCE_TAG=$(if $(SINCE),$(SINCE),$(BASE)); \
	if [ -z "$$SINCE_TAG" ]; then echo "Usage: make map-changelog SINCE=vX.Y.Z (or BASE=)"; exit 2; fi; \
	CMD="python3 tools/generate_map_changelog.py --since-tag $$SINCE_TAG"; \
	echo "Running: $$CMD" >&2; eval $$CMD
