# Release Guide (Practical Steps)

This guide complements `release-versioning.md` with hands-on commands.

## Prerequisites

- Write access (or fork + PR) to create/merge the release PR.
- `gh` CLI (optional convenience) and `cosign` if verifying locally.

## Standard Flow

1. Land conventional commits on `main`.
2. Wait for or trigger the Release Please PR (title like `chore(main): release <version>`).
3. Review generated CHANGELOG section & version bump classification.
4. Merge the PR (squash/merge). Tag + GitHub Release is created automatically.
5. Bundle/sign workflows run and attach artifacts (bundle, manifest, SBOMs, provenance, signatures).
6. (Optional) Deploy docs when publishing publicly.

## Manual Trigger

If urgent:

- Use GitHub Actions workflow dispatch for `release-please` with appropriate inputs (defaults usually fine).

## Verifying Artifacts

Example verification (digest + signature + provenance) once assets exist:

```bash
DIGEST=$(grep -E 'bundle_sha256' manifest.json | awk -F '"' '{print $4}')
COSIGN_EXPERIMENTAL=1 cosign verify \
  --certificate-identity-regexp ".*github.com/rulehub/rulehub.*" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/rulehub/rulehub-bundle@sha256:${DIGEST}
```

Provenance (SLSA generator) attestation fetch via GH API or `cosign verify-attestation` using the same identity flags.

## Hotfixes

- Commit `fix:` changes to a branch off the current release tag or `main` (preferred if clean).
- Ensure no unrelated pending `feat:` commits if you intend only a PATCH bump; otherwise accept a MINOR bump.


## When to Use MAJOR vs Feature Flags

Prefer feature flags (config inputs) if you can preserve old logic by default. Use a MAJOR bump only when keeping backward logic would cause risk or complexity.

## Checklist Before Merging Release PR

- [ ] CHANGELOG entry reads cleanly (no internal noise).
- [ ] Version bump matches intent (feat -> MINOR, fix -> PATCH, breaking -> MAJOR).
- [ ] No leftover `TODO` markers in policy or metadata for this release scope.
- [ ] SBOM workflow succeeded in CI.
// Deny rule usage scan present in CI; repository baseline already standardized on deny[]

## Post-Release

- Announce (issue discussion / social if desired).
- Collect feedback; open follow-up issues for any regressions quickly.

---

For deeper semantic rules see `release-versioning.md`.
