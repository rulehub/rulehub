# Security and Provenance Artifacts

This document describes the security, integrity, and transparency artifacts published with releases (and optionally main branch snapshots).

## Published Artifacts (per release / tagged build)

| Artifact | Location | Purpose |
|----------|----------|---------|
| OPA bundle | `dist/opa-bundle.tar.gz` + GH Release asset + GHCR (OCI layer) | Policy distribution (Rego / constraints) |
| Signature | `dist/opa-bundle.tar.gz.sig` | Integrity + origin (Sigstore keyless) |
| Certificate | `dist/opa-bundle.tar.gz.cert` | Fulcio cert binding signature to GitHub workflow identity |
| SBOM (CycloneDX) | `dist/opa-bundle.sbom.cdx.json` | Dependency / component inventory (CycloneDX tooling) |
| SBOM (SPDX) | `dist/opa-bundle.sbom.spdx.json` | License / compliance workflows (SPDX tooling) |
| SBOM attestations | OCI attestations (`type=cyclonedx`, `type=spdx`) | Bind SBOMs to the pushed OCI artifact |
| SLSA v1 provenance attestation | OCI attestation (`type=slsaprovenance`) | Build provenance (SLSA Level 3 via official generator) |
| Generator provenance artifact | Release asset (name: `rulehub-opa-bundle.provenance.intoto.jsonl` or similar) | Downloadable in-toto statement for offline verification |

Artifacts are attached to GitHub Releases. The bundle is published to `ghcr.io/rulehub/rulehub-bundle:<tag>` (tag = release tag or main snapshot) along with attestations.

## 1. Verifying the Bundle Signature (Blob)

Use cosign keyless verification:

```bash
cosign verify-blob \
  --certificate dist/opa-bundle.tar.gz.cert \
  --signature dist/opa-bundle.tar.gz.sig \
  dist/opa-bundle.tar.gz
```

Optional flags:

- `--certificate-identity-regexp` to restrict the expected subject (e.g., your repository path)
- `--certificate-oidc-issuer-regexp` to restrict the OIDC issuer (e.g., `https://token.actions.githubusercontent.com`)

## 2. SBOMs (CycloneDX & SPDX)

Two SBOM formats are generated from the built bundle with Syft and:

- stored as release assets,
- uploaded as workflow artifacts,
- attested to the OCI artifact (so consumers can pull them via referrers / cosign).

Presence (non-empty) is enforced in the `verify-bundle-artifacts` job.

## 3. Provenance (SLSA Level 3)

Provenance is produced by the official reusable workflow `slsa-framework/slsa-github-generator` (generic SLSA3). This yields an in-toto statement attested to the OCI artifact (predicate type `slsaprovenance`) and uploaded as a release/downloadable artifact.

Retrieve and verify the provenance attestation (public registry scenario):

```bash
cosign verify-attestation \
  --type slsaprovenance \
  ghcr.io/<org>/rulehub-bundle:<tag> > attestation.jsonl

grep sha256 attestation.jsonl
```

Add identity constraints (recommended):

```bash
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-identity-regexp "https://github.com/<org>/<repo>/.*" \
  --certificate-oidc-issuer-regexp '^https://token.actions.githubusercontent.com$' \
  ghcr.io/<org>/rulehub-bundle:<tag>
```

The statement's `subject` digest must match the bundle SHA256 published in logs. The repository commit SHA should appear in materials. Consumers can further enforce policy (e.g., required builder ID / workflow path) with `cosign verify-attestation` flags.

## 4. Analysis & Tooling Suggestions

| Format | Typical Uses | Notes |
|--------|--------------|-------|
| CycloneDX | Vulnerability & dependency graph tools, BOM diffing | Broad ecosystem support (Grype, Dependency-Track, etc.) |
| SPDX | License compliance, provenance ingestion in legal tooling | SPDX JSON v2.3 generated directly (no conversion loss) |

Conversion between formats is optional (Syft already emits both). Downstream systems can choose their preferred format.

## 5. Future Enhancements

Potential roadmap:

- SBOM diffing & drift detection between releases (flag unexpected component additions/removals).
- Automated vulnerability scanning + vulnerability attestations (VEX / SARIF to attestation).
- Policy-level provenance (splitting bundle into logical subcomponents with separate subjects if needed).
- Rekor transparency log monitoring / alerting on signature anomalies.

Open an issue to propose additional integrity artifacts or verification policies.
