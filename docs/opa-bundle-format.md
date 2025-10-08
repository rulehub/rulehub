# OPA Bundle Artifact Format & Verification

This document details the structure of the RuleHub OPA bundle (`dist/opa-bundle.tar.gz`) and how to verify its integrity and authenticity using the external manifest and `cosign`.

## Artifact Set

| File                            | Purpose                                                     | Producer                                    |
| ------------------------------- | ----------------------------------------------------------- | ------------------------------------------- |
| `dist/opa-bundle.tar.gz`        | OPA bundle (Rego modules + OPA internal .manifest)          | `make opa-bundle` (`opa build -b policies`) |
| `dist/opa-bundle.manifest.json` | External manifest: file inventory + hashes + build metadata | `make opa-bundle-manifest`                  |
| `dist/opa-bundle.<format>.json` | SBOM (spdx-json, cyclonedx-json, etc.)                      | `make sbom-opa-bundle`                      |
| `dist/opa-bundle.tar.gz.sig`    | Cosign signature (blob)                                     | `make sign-opa-bundle`                      |
| `dist/opa-bundle.tar.gz.pem`    | Cosign certificate (Fulcio, keyless)                        | `make sign-opa-bundle`                      |

Optional (future / OCI): provenance & SBOM attestations attached to the OCI artifact.

## External Manifest Schema (v1)

```
schema_version: 1
build_commit: <git sha>
build_time: <RFC3339 UTC>
policies: [ { path, sha256, bytes }, ... ]
aggregate_hash: sha256( join('\n', '<sha256>  <path>' sorted by path) )
```

Semantics:

- `policies[]` lists every source file included (policy `.rego` + `metadata.yaml`, tests excluded when `--exclude-tests`).
- Individual file integrity: per-entry `sha256` + `bytes`.
- `aggregate_hash` is a deterministic roll-up (sensitive to order, content, and membership) providing tamper evidence with a single digest.
- `build_commit` ties the manifest to a repository state for traceability.

## Verification Layers

1. File-level hashing (per policy source file) - detects modification.
2. Aggregate hash - detects insertion, deletion, reordering, or hash substitution.
3. Cosign signature over the bundle tarball (`sign-blob`) - cryptographic integrity + origin (GitHub OIDC / Fulcio cert) of the packaged result.
4. Optional: cosign signature (or future attestation) over the manifest itself.
5. SBOM - transparency of included components, enabling vulnerability & license workflows.

## Build & Verify Workflow

Build:

```bash
make opa-bundle
make opa-bundle-manifest
make sbom-opa-bundle   # optional
```

Sign (keyless default):

```bash
make sign-opa-bundle   # produces .sig and .pem
```

Cryptographic verification (signature only):

```bash
make verify-opa-bundle  # wraps cosign verify-blob
```

Structural + hash verification:

```bash
make verify-bundle  # wraps tools/verify_bundle.py
```

Manual invocation example:

```bash
python tools/verify_bundle.py \
  --manifest dist/opa-bundle.manifest.json \
  --bundle dist/opa-bundle.tar.gz \
  --policies-root policies \
  --bundle-sig dist/opa-bundle.tar.gz.sig \
  --bundle-cert dist/opa-bundle.tar.gz.pem
```

Expected output includes INFO lines for successful cosign checks and a final `OK: bundle integrity verified`.

## Failure Modes & Interpretation

| Failure               | Likely Cause                                          | Action                                  |
| --------------------- | ----------------------------------------------------- | --------------------------------------- |
| Missing manifest keys | Corrupt / wrong file                                  | Regenerate manifest                     |
| Hash mismatch (file)  | Local tampering / stale manifest                      | Rebuild & regenerate manifest           |
| Size mismatch         | Partial write or corruption                           | Rebuild bundle                          |
| Aggregate mismatch    | Added/removed/reordered file or altered hash list     | Regenerate manifest & investigate diffs |
| Git HEAD mismatch     | Manifest from different commit                        | Rebuild or pin commit                   |
| Cosign verify fail    | Wrong signature, tampering, missing Fulcio trust root | Re-sign or validate environment         |
| Missing bundle member | Packaging issue (`opa build`) or manual edit          | Rebuild bundle                          |

## OCI Distribution

Publishing (example):

```bash
make oras-publish IMAGE=ghcr.io/rulehub/rulehub-bundle TAG=vX.Y.Z
```

Adds OCI annotations including `io.rulehub.manifest.sha256`. Optional signing:

```bash
make oras-publish IMAGE=ghcr.io/rulehub/rulehub-bundle TAG=vX.Y.Z SIGN=1
```

Later verification (OCI):

```bash
COSIGN_EXPERIMENTAL=1 cosign verify ghcr.io/rulehub/rulehub-bundle:vX.Y.Z
oras pull ghcr.io/rulehub/rulehub-bundle:vX.Y.Z -o dist/
```

## Local Evaluation Example

```bash
opa eval -b dist/opa-bundle.tar.gz -i input.json \
  "data.rulehub.k8s.no_run_as_root.deny"
```

## Future Enhancements

- Sign / attest manifest directly.
- Add `bundle_sha256` to manifest for explicit cross-reference.
- Generate SLSA provenance and in-toto attestations automatically.
- Policy-level sub-bundle segmentation (domain-scoped bundles) for selective consumption.
