# Versioning & Release Policy

This project follows Semantic Versioning (SemVer) for all published artifacts (OPA bundle OCI image + GitHub Release assets + documentation site).

## SemVer Recap

- MAJOR (X): Incremented for backwards-incompatible changes to policy behavior, structure or removal/rename of policy packages, metadata fields or compliance map schemas.
- MINOR (Y): Backwards-compatible additions: new policies, new metadata fields (optional), new compliance maps, non-breaking rule logic enhancements, added annotations.
- PATCH (Z): Backwards-compatible fixes: bug fixes to policy logic that tighten correctness without expanding required inputs; documentation-only updates; build or CI adjustments with no policy effect.

Example: `v1.4.2` means Major=1, Minor=4, Patch=2.

## What Constitutes a Breaking Change?

Any change that could cause existing users integrating the bundle to fail evaluation or produce different DENY/ALLOW outcomes under the same inputs unless they opt-in. Examples:

1. Removing or renaming a policy package or rule used by consumers.
2. Changing required input document structure or field semantics.
3. Tightening a rule to produce new DENY results by default (unless gated behind a feature flag / configuration parameter with default preserving old behavior).
4. Renaming / removing top-level metadata keys (e.g., in compliance maps) or altering existing key meaning.
5. Changing manifest schema_version.

If unsure, treat the change as breaking and schedule it for the next MAJOR release with clear release notes.

## Non-Breaking Enhancements (Minor)

Examples of safe MINOR increments:

- Adding new independent policies.
- Adding optional metadata fields (defaulting to null / absent).
- Expanding coverage maps with new categories (without altering existing keys).
- Performance optimizations not affecting evaluation outcome.
- Adding new annotations, SBOM formats, attestations, or documentation pages.
- Logic corrections that only reduce false negatives or false positives without requiring new input fields and are unlikely to break pipelines.
- Documentation, examples, README, site content changes.
- CI/workflow improvements not altering published artifact contents (hash stable) - if the bundle bytes change due to a policy fix, it is at minimum a PATCH.


## Patch Changes

- Logic corrections that only reduce false negatives or false positives without requiring new input fields and are unlikely to break pipelines.
- Documentation, examples, README, site content changes.
- CI/workflow improvements not altering published artifact contents (hash stable) - if the bundle bytes change due to a policy fix, it is at minimum a PATCH.

## Pre-1.0.0 Policy

Before `v1.0.0`, minor version bumps (0.Y.Z) may include changes that would otherwise be considered breaking. We still aim to minimize breakage and document any incompatible changes clearly in the CHANGELOG.

## Release Flow

1. Merge changes to `main` - automated publish workflow builds snapshot bundle (`main-<shortsha>` tag in GHCR) with manifest + SBOM + signatures + provenance.
2. Prepare a release PR using `release-please` (generates updated CHANGELOG and version bump proposal based on commit conventions).
3. On tag push / GitHub Release publish (`vX.Y.Z`), the workflow rebuilds, signs, attests and attaches artifacts to the Release.
4. Docs site (MkDocs) can be deployed separately (`make docs-deploy`) - ensure `site_url` matches GitHub Pages.
5. Consumers pin exact tags or immutable digests (recommended: digest from provenance / manifest integrity verification).

## Commit & Changelog Conventions

Use conventional commit-like prefixes to aid automated tooling (not strictly enforced yet):

- `feat(policy): ...` new policy or enhancement (likely MINOR)
- `fix(policy): ...` logic correction (PATCH)
- `refactor(policy): ...` internal change (PATCH unless behavior changes)
- `break(policy)!: ...` denotes breaking change (MAJOR) - include migration notes.
- `docs: ...` documentation only.
- `build|ci|chore: ...` infra / tooling.

`release-please` interprets these to decide version bump. Add `!` to force a major bump if necessary.

## Manifest & Integrity Versioning

- `schema_version` in manifest increments independently when manifest structure changes. Such a change is considered at least MINOR; if consumers depend on old structure without fallback, it may be MAJOR.
Keep backward compatibility by adding fields rather than renaming/removing; prefer documenting recommended replacements and migration notes.


## Consumer Guidance

- For stability: pin a digest + verify signature & provenance.
- For faster updates: track a MAJOR version tag (`v1` style mutable tag) once established post-1.0.0 (not yet implemented pre-1.0.0).

## Future Automation

Planned enhancements:

- Enforce commit message lint for version classification.
- Automated opening of breaking-change issue template when `!` detected.
- Mutable major stream tags (`v1`, `v2`) updated by release workflow.

## Feedback

Open an issue with proposals for additional versioning signals (e.g., policy maturity levels) or more granular compatibility guarantees.
