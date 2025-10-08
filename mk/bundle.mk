# OPA bundle build, SBOM, signing, integrity

.PHONY: opa-bundle opa-bundle-manifest opa-bundle-provenance opa-bundle-all sbom-opa-bundle sign-opa-bundle verify-opa-bundle verify-bundle dist-manifest verify-dist-manifest verify-all-integrity bundle-deterministic artifacts-verify sign-oci oras-publish zip-backup

# Build a single OPA bundle from the policies/ tree
opa-bundle:
	@command -v opa >/dev/null 2>&1 || { echo "OPA not found. See https://www.openpolicyagent.org/docs/latest/#running-opa"; exit 127; }
	@mkdir -p dist
	opa build -b policies -o dist/opa-bundle.tar.gz
	@echo "Built dist/opa-bundle.tar.gz"

opa-bundle-manifest: ## Generate manifest for existing bundle
	@test -f dist/opa-bundle.tar.gz || { echo "Bundle not found. Run 'make opa-bundle' first."; exit 3; }
	python3 tools/generate_bundle_manifest.py --output dist/opa-bundle.manifest.json --policies-root policies --exclude-tests

opa-bundle-provenance: ## Generate simplified provenance statement (in-toto style)
	@test -f dist/opa-bundle.tar.gz || { echo "Bundle not found. Run 'make opa-bundle' first."; exit 3; }
	@test -f dist/opa-bundle.manifest.json || { echo "Manifest not found. Run 'make opa-bundle-manifest' first."; exit 3; }
	python3 tools/generate_provenance.py --bundle dist/opa-bundle.tar.gz --manifest dist/opa-bundle.manifest.json --output dist/opa-bundle.provenance.json

opa-bundle-all: opa-bundle opa-bundle-manifest sbom-opa-bundle opa-bundle-provenance ## Bundle + manifest + SBOM + provenance
	@echo "Bundle + manifest + SBOM + provenance complete"

# SBOM & signing
SBOM_FORMAT ?= spdx-json
SBOM_OUT ?= dist/opa-bundle.$(SBOM_FORMAT).json
sbom-opa-bundle: ## Generate SBOM for dist/opa-bundle.tar.gz
	@command -v syft >/dev/null 2>&1 || { echo "Syft not found. Install via 'brew install syft' or see https://github.com/anchore/syft"; exit 127; }
	@test -f dist/opa-bundle.tar.gz || { echo "dist/opa-bundle.tar.gz not found. Run 'make opa-bundle' first."; exit 3; }
	@echo "Generating SBOM ($(SBOM_FORMAT)) -> $(SBOM_OUT)"
	syft packages dist/opa-bundle.tar.gz -o $(SBOM_FORMAT) > $(SBOM_OUT)
	@echo "Wrote $(SBOM_OUT)"

sign-opa-bundle: ## Cosign sign dist/opa-bundle.tar.gz (produces .sig/.cert)
	@command -v cosign >/dev/null 2>&1 || { echo "Cosign not found. Install from https://docs.sigstore.dev/cosign/"; exit 127; }
	@test -f dist/opa-bundle.tar.gz || { echo "dist/opa-bundle.tar.gz not found. Run 'make opa-bundle' first."; exit 3; }
	@echo "Signing dist/opa-bundle.tar.gz (keyless if no key supplied)"
	COSIGN_EXPERIMENTAL=1 cosign sign-blob dist/opa-bundle.tar.gz \
	  --output-signature dist/opa-bundle.tar.gz.sig \
	  --output-certificate dist/opa-bundle.tar.gz.pem
	@echo "Signature: dist/opa-bundle.tar.gz.sig"
	@echo "Certificate: dist/opa-bundle.tar.gz.pem"

verify-opa-bundle: ## Verify Cosign signature for dist/opa-bundle.tar.gz
	@command -v cosign >/dev/null 2>&1 || { echo "Cosign not found."; exit 127; }
	@test -f dist/opa-bundle.tar.gz.sig || { echo "Signature file missing. Run 'make sign-opa-bundle' first."; exit 3; }
	@test -f dist/opa-bundle.tar.gz.pem || { echo "Certificate file missing. Run 'make sign-opa-bundle' first."; exit 3; }
	COSIGN_EXPERIMENTAL=1 cosign verify-blob dist/opa-bundle.tar.gz \
	  --signature dist/opa-bundle.tar.gz.sig \
	  --certificate dist/opa-bundle.tar.gz.pem
	@echo "Verified signature for dist/opa-bundle.tar.gz"

verify-bundle: ## Verify bundle integrity against manifest (hashes, sizes, aggregate, members)
	@test -f dist/opa-bundle.manifest.json || { echo "Manifest dist/opa-bundle.manifest.json not found."; exit 3; }
	@test -f dist/opa-bundle.tar.gz || { echo "Bundle dist/opa-bundle.tar.gz not found."; exit 3; }
	python3 tools/verify_bundle.py \
	  --manifest dist/opa-bundle.manifest.json \
	  --bundle dist/opa-bundle.tar.gz \
	  --policies-root policies

dist-manifest: ## Generate dist/dist.manifest.json listing all artifacts (hash + size)
	@mkdir -p dist
	python3 tools/generate_dist_manifest.py --output dist/dist.manifest.json

verify-dist-manifest: ## Verify dist/ matches dist/dist.manifest.json
	@test -f dist/dist.manifest.json || { echo "dist/dist.manifest.json not found. Run 'make dist-manifest' first."; exit 3; }
	python3 tools/verify_dist_manifest.py --manifest dist/dist.manifest.json --dist-dir dist

verify-all-integrity: ## Aggregate: bundle + bundle manifest + dist manifest cross consistency
	@test -f dist/opa-bundle.manifest.json || { echo "Bundle manifest missing (run 'make opa-bundle-manifest')"; exit 3; }
	@test -f dist/dist.manifest.json || { echo "Dist manifest missing (run 'make dist-manifest')"; exit 3; }
	@test -f dist/opa-bundle.tar.gz || { echo "Bundle tarball missing (run 'make opa-bundle')"; exit 3; }
	python3 tools/verify_integrity_pipeline.py --bundle-manifest dist/opa-bundle.manifest.json --dist-manifest dist/dist.manifest.json --bundle dist/opa-bundle.tar.gz --policies-root policies

bundle-deterministic: ## Build bundle twice and assert identical SHA256 digest
	@command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum not found"; exit 127; }
	@command -v opa >/dev/null 2>&1 || { echo "OPA not found"; exit 127; }
	@mkdir -p dist
	opa build -b policies -o dist/opa-bundle-1.tar.gz >/dev/null
	opa build -b policies -o dist/opa-bundle-2.tar.gz >/dev/null
	SHA1=$$(sha256sum dist/opa-bundle-1.tar.gz | awk '{print $$1}'); \
	SHA2=$$(sha256sum dist/opa-bundle-2.tar.gz | awk '{print $$1}'); \
	if [ "$$SHA1" != "$$SHA2" ]; then \
	  echo "[bundle-deterministic] mismatch: $$SHA1 != $$SHA2" >&2; exit 2; \
	else \
	  echo "[bundle-deterministic] OK $$SHA1"; \
	fi

artifacts-verify: ## Verify required release artifacts exist (bundle, manifest, SBOMs (CycloneDX+SPDX), signature/cert if signed)
	@missing=0; \
	# Core required artifacts
	for f in dist/opa-bundle.tar.gz dist/opa-bundle.manifest.json; do \
	  [ -f $$f ] || { echo "[artifacts-verify] missing $$f" >&2; missing=1; }; \
	done; \
	# New SBOM file names (both formats expected)
	for sb in dist/opa-bundle.sbom.cdx.json dist/opa-bundle.sbom.spdx.json; do \
	  if [ ! -f $$sb ]; then \
	    echo "[artifacts-verify] missing $$sb" >&2; missing=1; \
	  fi; \
	done; \
	# Backwards compatibility: warn if old generic SBOM filename still present
	if [ -f dist/opa-bundle.sbom.json ]; then \
	  echo "[artifacts-verify] note: old dist/opa-bundle.sbom.json present (prefer cdx/spdx split)" >&2; \
	fi; \
	# Signature implies certificate
	if ls dist/opa-bundle.tar.gz.sig >/dev/null 2>&1; then \
	  [ -f dist/opa-bundle.tar.gz.pem ] || { echo "[artifacts-verify] signature present but cert missing" >&2; missing=1; }; \
	fi; \
	if [ $$missing -ne 0 ]; then echo "[artifacts-verify] FAIL" >&2; exit 2; else echo "[artifacts-verify] OK"; fi

# Publish bundle to OCI with proper mediaType using ORAS CLI
# Usage: make oras-publish IMAGE=ghcr.io/rulehub/rulehub-bundle TAG=<tag>
oras-publish:
	@if [ -z "$(IMAGE)" ] || [ -z "$(TAG)" ]; then \
		echo "Usage: make oras-publish IMAGE=ghcr.io/rulehub/rulehub-bundle TAG=<tag>"; exit 2; \
	fi
	@command -v oras >/dev/null 2>&1 || { echo "ORAS not found. See https://oras.land/ for install"; exit 127; }
	@test -f dist/opa-bundle.tar.gz || { echo "Bundle not found. Run 'make opa-bundle' first."; exit 3; }
	@test -f dist/opa-bundle.manifest.json || { echo "Manifest not found. Run 'make opa-bundle-manifest' first."; exit 3; }
	MANIFEST_HASH=$$(sha256sum dist/opa-bundle.manifest.json | awk '{print $$1}'); \
	BUILD_COMMIT=$$(jq -r '.build_commit' dist/opa-bundle.manifest.json); \
	CREATED=$$(date -u +%Y-%m-%dT%H:%M:%SZ); \
	oras push $(IMAGE):$(TAG) \
	  dist/opa-bundle.tar.gz:application/vnd.opa.bundle.layer.v1+tar \
	  --annotation org.opencontainers.image.title="RuleHub OPA bundle" \
	  --annotation org.opencontainers.image.source="$$GITHUB_REPOSITORY" \
	  --annotation org.opencontainers.image.revision="$$BUILD_COMMIT" \
	  --annotation org.opencontainers.image.created="$$CREATED" \
	  --annotation io.rulehub.manifest.sha256="$$MANIFEST_HASH"
	@if [ "$(SIGN)" = "1" ]; then \
	  command -v cosign >/dev/null 2>&1 || { echo "Cosign not found. Install from https://docs.sigstore.dev/cosign/"; exit 127; }; \
	  echo "Signing OCI artifact with Cosign (keyless)"; \
	  COSIGN_EXPERIMENTAL=1 cosign sign --yes $(IMAGE):$(TAG); \
	fi
	@echo "Published $(IMAGE):$(TAG)"

sign-oci: ## Cosign sign $(IMAGE):$(TAG) (keyless)
	@if [ -z "$(IMAGE)" ] || [ -z "$(TAG)" ]; then \
		echo "Usage: make sign-oci IMAGE=ghcr.io/rulehub/rulehub-bundle TAG=<tag>"; exit 2; \
	fi
	@command -v cosign >/dev/null 2>&1 || { echo "Cosign not found."; exit 127; }
	@echo "Signing OCI artifact $(IMAGE):$(TAG) (keyless)"
	COSIGN_EXPERIMENTAL=1 cosign sign --yes $(IMAGE):$(TAG)
	@echo "Signed $(IMAGE):$(TAG)"

zip-backup: ## Create a zip archive of all git-tracked files with a timestamped name
	@ARCHIVE=rulehub-backup-`date +%F`.zip; \
	git ls-files | zip -@ $$ARCHIVE; \
	echo "Created $$ARCHIVE with all git-tracked files."
