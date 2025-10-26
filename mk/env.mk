# Environment and dependency management

.PHONY: setup-dev pre-commit-install deps lock lock-dev python-lock-verify

setup-dev:
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	# If venv didn't create a python (Arch may strip bits), try virtualenv fallback
	@if [ ! -x "$(VENV)/bin/python" ]; then \
	  echo "[setup-dev] $(VENV)/bin/python missing, trying '$(PY) -m virtualenv $(VENV)'"; \
	  $(PY) -m virtualenv $(VENV) >/dev/null 2>&1 || true; \
	fi
	@if [ ! -x "$(VENV)/bin/python" ]; then \
	  echo "[setup-dev] FATAL: Unable to create venv (python missing). Ensure python-virtualenv is installed."; \
	  echo "           Suggested: pacman -S --needed python-pip python-virtualenv (Arch)"; \
	  exit 127; \
	fi
	# Ensure pip exists inside the venv
	@if [ ! -x "$(VENV)/bin/pip" ]; then \
	  echo "[setup-dev] venv pip missing; attempting ensurepip"; \
	  $(VENV)/bin/python -Im ensurepip --upgrade >/dev/null 2>&1 || true; \
	fi
	@if [ ! -x "$(VENV)/bin/pip" ]; then \
	  echo "[setup-dev] ensurepip not available; installing virtualenv with user pip and recreating venv"; \
	  $(PY) -Im pip install --user -U virtualenv >/dev/null 2>&1 || true; \
	  $(PY) -m virtualenv --clear $(VENV) >/dev/null 2>&1 || true; \
	fi
	@if [ ! -x "$(VENV)/bin/pip" ]; then \
	  echo "[setup-dev] FATAL: pip still missing in venv. Please install system pip/virtualenv and retry."; \
	  exit 127; \
	fi
	# Prefer invoking pip as a module
	$(VENV)/bin/python -Im pip install -U pip
	@if [ -f requirements-dev.lock ]; then \
	  $(VENV)/bin/python -Im pip install -r requirements-dev.lock; \
	else \
	  $(VENV)/bin/python -Im pip install -r requirements-dev.txt; \
	fi

pre-commit-install:
	$(VENV)/bin/pre-commit install

deps:
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	# If venv didn't create a python (Arch may strip bits), try virtualenv fallback
	@if [ ! -x "$(VENV)/bin/python" ]; then \
	  echo "[deps] $(VENV)/bin/python missing, trying '$(PY) -m virtualenv $(VENV)'"; \
	  $(PY) -m virtualenv $(VENV) >/dev/null 2>&1 || true; \
	fi
	@if [ ! -x "$(VENV)/bin/python" ]; then \
	  echo "[deps] FATAL: Unable to create venv (python missing). Ensure python-virtualenv is installed."; \
	  echo "       Suggested: pacman -S --needed python-pip python-virtualenv (Arch)"; \
	  exit 127; \
	fi
	# Ensure pip exists inside the venv
	@if [ ! -x "$(VENV)/bin/pip" ]; then \
	  echo "[deps] venv pip missing; attempting ensurepip"; \
	  $(VENV)/bin/python -Im ensurepip --upgrade >/dev/null 2>&1 || true; \
	fi
	@if [ ! -x "$(VENV)/bin/pip" ]; then \
	  echo "[deps] ensurepip not available; installing virtualenv with user pip and recreating venv"; \
	  $(PY) -Im pip install --user -U virtualenv >/dev/null 2>&1 || true; \
	  $(PY) -m virtualenv --clear $(VENV) >/dev/null 2>&1 || true; \
	fi
	@if [ ! -x "$(VENV)/bin/pip" ]; then \
	  echo "[deps] FATAL: pip still missing in venv. Please install system pip/virtualenv and retry."; \
	  exit 127; \
	fi
	$(VENV)/bin/python -Im pip install -U pip
	$(VENV)/bin/python -Im pip install -r requirements.txt

# Generate lock files with pip-tools, using Python marker and hashes for reproducibility
lock:
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	# Pin pip-tools to a version compatible with modern pip (avoid use_pep517 attr errors)
	$(PIP) install "pip-tools>=7.9,<9" >/dev/null
	$(VENV)/bin/pip-compile \
	  --upgrade \
	  --generate-hashes \
	  --quiet \
	  --resolver=backtracking \
	  --output-file requirements.lock \
	  requirements.txt

lock-dev:
	@test -d $(VENV) || $(PY) -m venv $(VENV)
	$(PIP) install -U pip >/dev/null
	# Pin pip-tools to a version compatible with modern pip (avoid use_pep517 attr errors)
	$(PIP) install "pip-tools>=7.9,<9" >/dev/null
	$(VENV)/bin/pip-compile \
	  --upgrade \
	  --generate-hashes \
	  --quiet \
	  --resolver=backtracking \
	  --allow-unsafe \
	  --output-file requirements-dev.lock \
	  requirements-dev.txt

# Verify lock files are up to date (mirrors CI job)
python-lock-verify:
	@bash .github/scripts/verify_python_locks.sh
