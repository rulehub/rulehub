# Release & Integrity

This page describes the integrity metadata and verification flow for RuleHub bundles.

Artifacts:

- OPA bundle: `dist/opa-bundle.tar.gz`
- Manifest: `dist/opa-bundle.manifest.json`
- SBOM: `dist/opa-bundle.<format>.json`
- Signatures: `*.sig` / `*.pem` (cosign keyless by default)
- Provenance (planned): `dist/provenance.json` attested via `cosign attest`

Manifest schema (v1):

```text
schema_version: 1
build_commit: <git sha>
build_time: <RFC3339 UTC>
policies: [ { path, sha256, bytes }, ... ]
aggregate_hash: sha256( join('\n', '<sha256>  <path>' sorted by path) )
```

Verification steps:

1. Recompute file hashes for each listed path.
2. Recompute aggregate hash and compare.
3. Validate git commit (optional offline).
4. Verify cosign signatures (bundle + manifest).
5. (Planned) Verify provenance predicate subject digest matches bundle + manifest hash.

CLI helper: `make verify-bundle` (wraps `tools/verify_bundle.py`).

Upcoming:

- Add provenance predicate generation target.
- Extend manifest with `policy_count` and `bundle_sha256` (hash of tarball) for cross-check.
