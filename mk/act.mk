# Local GitHub Actions via act

ACT ?= act
# Auto-detect container architecture for act (override with ACT_ARCH=linux/amd64 or linux/arm64)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),arm64)
	DEFAULT_ACT_ARCH := linux/arm64
else ifeq ($(UNAME_M),aarch64)
	DEFAULT_ACT_ARCH := linux/arm64
else ifeq ($(UNAME_M),x86_64)
	DEFAULT_ACT_ARCH := linux/amd64
endif
ACT_ARCH ?= $(DEFAULT_ACT_ARCH)
ARCH_FLAG := $(if $(ACT_ARCH),--container-architecture $(ACT_ARCH),)
WF ?= .github/workflows/python-tests.yml
EVENT ?= push
JOB ?=
ARGS ?=

.PHONY: act-list act-python-tests act-python-tests-all act-opa-bundle act-run act-all-push

# Variables (override on invocation):
#   WF    - path to workflow file (default .github/workflows/python-tests.yml)
#   EVENT - event name (push, pull_request, release, workflow_dispatch, etc.)
#   JOB   - optional job name to limit execution
#   ARGS  - extra args passed verbatim to act (e.g. "--matrix python-version=3.11 -s SKIP_SUPPLYCHAIN=1")
# Examples:
#   make act-list
#   make act-python-tests
#   make act-run WF=.github/workflows/opa-bundle-publish.yml ARGS='-s SKIP_SUPPLYCHAIN=1'
#   make act-run EVENT=push WF=.github/workflows/python-tests.yml JOB=tests ARGS='--matrix python-version=3.13'

act-list:
	@command -v $(ACT) >/dev/null 2>&1 || { echo "act not found. Install via 'brew install act'"; exit 127; }
	@echo "[act] architecture: $(ACT_ARCH)"; \
	$(ACT) $(ARCH_FLAG) -l

act-python-tests:
	@command -v $(ACT) >/dev/null 2>&1 || { echo "act not found. Install via 'brew install act'"; exit 127; }
	@echo "[act] architecture: $(ACT_ARCH)"; \
	$(ACT) $(ARCH_FLAG) push -W .github/workflows/python-tests.yml -j tests --matrix python-version=3.11 $(ARGS)

act-python-tests-all:
	@command -v $(ACT) >/dev/null 2>&1 || { echo "act not found. Install via 'brew install act'"; exit 127; }
	@echo "[act] architecture: $(ACT_ARCH)"; \
	$(ACT) $(ARCH_FLAG) push -W .github/workflows/python-tests.yml $(ARGS)

act-opa-bundle:
	@command -v $(ACT) >/dev/null 2>&1 || { echo "act not found. Install via 'brew install act'"; exit 127; }
	@echo "[act] architecture: $(ACT_ARCH)"; \
	ACTIONS_RUNTIME_TOKEN=dummy ACTIONS_RESULTS_URL=http://localhost \
	$(ACT) $(ARCH_FLAG) push -W .github/workflows/opa-bundle-publish.yml -s SKIP_SUPPLYCHAIN=1 $(ARGS)

act-run:
	@command -v $(ACT) >/dev/null 2>&1 || { echo "act not found. Install via 'brew install act'"; exit 127; }
	@echo "[act] architecture: $(ACT_ARCH)"; \
	$(ACT) $(ARCH_FLAG) $(EVENT) -W $(WF) $(if $(JOB),-j $(JOB),) $(ARGS)

act-all-push: ## Run all workflows (push event); set ARGS="-s SKIP_SUPPLYCHAIN=1" to skip supply chain steps
	@command -v $(ACT) >/dev/null 2>&1 || { echo "act not found. Install via 'brew install act'"; exit 127; }
	@echo "[act] architecture: $(ACT_ARCH)"; \
	set -e; \
	for wf in .github/workflows/*.yml .github/workflows/*.yaml; do \
	  [ -f "$$wf" ] || continue; \
	  echo "===== Running $$wf (push) ====="; \
	  $(ACT) $(ARCH_FLAG) push -W "$$wf" $(ARGS) || { echo "Workflow $$wf failed"; exit 1; }; \
	  echo "===== Done $$wf ====="; \
	done; \
	echo "All push workflows completed.";
