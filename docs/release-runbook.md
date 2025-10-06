---
title: Release Runbook
---

Authoritative, task‑oriented sequence for preparing and publishing a
RuleHub release. This file supersedes the former root
`RELEASE_CHECKLIST.md` (now removed) so the content is available in the
published documentation site. Root compliance files (`SECURITY.md`,
`SUPPORT.md`, `CODE_OF_CONDUCT.md`) remain at repository top level as
required by GitHub.

## Preparation

- [ ] Update dev environment: `make setup-dev` (or ensure virtualenv active)
- [ ] Quick hygiene:
  - [ ] YAML: `make lint-yaml` (or `npx @stoplight/spectral lint --ruleset .spectral.yml .`)
  - [ ] TS/TSX: (n/a - plugin in separate repo)
  - [ ] Python: `ruff check .` (optionally `ruff format`)

## Versioning & CHANGELOG

- [ ] Pick release version (semver): `<major.minor.patch>`
- [ ] Bump versions:
  - [ ] Backstage plugin: version handled separately
- [ ] Update `CHANGELOG.md` (`[Unreleased]` -> new version section)

## Validation & Artifact Build

- [ ] Metadata validation: `make validate` (or `make validate-strict`)
- [ ] Coverage & catalog:
  - [ ] `make coverage` - refreshes `docs/coverage.md` & `dist/*`
  - [ ] `make catalog` - generates `dist/index.json` for plugin (Policy
        source sync now handled externally - skip here)

## Tests

- [ ] Kyverno CLI tests: `make test-kyverno`
- [ ] Gatekeeper/OPA tests: `make test-gatekeeper`

## Helm (external)

See `rulehub/rulehub-charts` repository for chart lint/render/package/publish steps.

## Backstage Plugin (NPM)

Released separately via `@rulehub/plugin-policy-catalog` repository (see its README/CI) - no steps here.

## OPA Bundle (OCI Publishing)

- [ ] Build: `make opa-bundle` (produces `dist/opa-bundle.tar.gz`)
- [ ] (Optional shortcut) All-in-one: `make opa-bundle-all` (bundle + manifest + SBOM in one step)
- [ ] Link audit drift: `make link-audit && make link-audit-diff` (ensure unexpected drift = 0 before tagging)
- [ ] Manifest: `make opa-bundle-manifest` (produces `dist/opa-bundle.manifest.json` - hashes & aggregate integrity)
- [ ] SBOM (default SPDX): `make sbom-opa-bundle` (creates
      `dist/opa-bundle.spdx-json.json` via Syft; override format with
      `SBOM_FORMAT=`; default output path shown in Makefile variable
      `SBOM_OUT`)
- [ ] (Alt) Combined CycloneDX + SPDX (CI): see workflow
      `opa-bundle-publish.yml` (generates
      `dist/opa-bundle.sbom.cdx.json` & `dist/opa-bundle.sbom.spdx.json`)
- [ ] (Optional) Sign bundle + manifest + SBOM: `make sign-opa-bundle`
      (blob signatures, produces `.sig` / `.pem`); for OCI artifact use
      `make sign-oci IMAGE=... TAG=...`
- [ ] (Optional) Verify signatures locally: `make verify-opa-bundle` (or manual `cosign verify-blob ...`)
- [ ] Integrity check (post-build): `make verify-bundle` (ensures manifest hashes match bundle contents)
- [ ] Determinism (spot check): `make bundle-deterministic` (two builds -> identical SHA256)
- [ ] Push to OCI: `make oras-publish IMAGE=ghcr.io/<org>/rulehub-bundle TAG=<tag>`
  - Requires ORAS CLI and authenticated login (`oras login ghcr.io`).
  - After push (CI): provenance & SBOM attestations generated/signature verification (see `opa-bundle-publish.yml`).

### SBOM Guidance

- Local quick path: run `make opa-bundle-all` to produce bundle, manifest, and an SPDX SBOM in one step.
- For multi-format SBOMs (CycloneDX + SPDX) rely on CI workflow; locally you can invoke Syft twice:
  - `syft packages dist/opa-bundle.tar.gz -o cyclonedx-json > dist/opa-bundle.sbom.cdx.json`
  - `syft packages dist/opa-bundle.tar.gz -o spdx-json > dist/opa-bundle.sbom.spdx.json`
- Always archive SBOM(s) with the release; verify presence via `make artifacts-verify`.
- When signing, sign each SBOM and manifest so consumers can verify integrity prior to policy ingestion.

## Finalization

- [ ] Update `CHANGELOG` / docs if needed
- [ ] (In plugin repo) bump npm package if API changed
- [ ] Create tag & GitHub release:
  - Tag: `v<version>` (e.g., `v0.1.0`), description from CHANGELOG
  - Release: attach / reference artifacts (OCI links helm/opa, npm version)

### Pre-publish sanity

- [ ] `Chart.yaml: version == <version>`
- [ ] `package.json: version == <version>` (plugin repo)
- [ ] `CHANGELOG.md: section <version>`

---

History: migrated from root `RELEASE_CHECKLIST.md` to
`docs/release-runbook.md` to be part of published documentation (MkDocs
navigation). The original file has been removed to reduce duplication.
