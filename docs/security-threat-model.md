# High-Level Threat Model: Metadata → Coverage Map → dist/index.json → Consumers

This document captures a pragmatic, evolving threat model for the RuleHub policy supply chain
from authoring time to downstream consumption.

## 1. Scope & Assets

Pipeline stages:
1. Source Metadata & Policies (`policies/**/metadata.yaml`, `policy.rego`, tests)
2. Tooling & Transformation (`tools/coverage_map.py`, metadata loaders, guardrails)
3. Generated Aggregates (`coverage.json`, `dist/index.json`, maps, bundle manifests)
4. Distribution Artifacts (OPA bundle, manifest, SBOMs, signatures, provenance)
5. Consumer Integration (CI/CD checks, admission controllers, reporting systems)



Primary assets:

- Policy logic (Rego) and associated metadata fields (id, severity, tags, links).
- Compliance maps (mapping policies to frameworks / sections).
- Integrity artifacts: bundle manifest hashes, signatures, provenance attestation.
- Index (`dist/index.json`) — canonical machine-readable catalog.


Security properties desired:
| Property | Description |
|----------|-------------|
| Integrity | Prevent unauthorized modification of policies, metadata, or generated index. |
| Authenticity | Demonstrate origin & build identity of artifacts. |
| Completeness | Ensure no silent omission of required policies in index/bundle. |
| Non-ambiguity | Prevent ID collisions / inconsistent metadata leading to misinterpretation. |
| Traceability | Ability to trace an index entry back to source commit & file path reliably. |


Out of scope (for now):

- Confidentiality (content is open)
- Fine‑grained authorization inside consumer clusters
- Runtime Rego evaluation threats

## 2. Data Flow (Textual)

```text
Authors → Git Repo (policies/, metadata/) → Guardrail / Lint (CI) →
  Coverage & Index Generation (coverage_map.py, loaders) → dist/index.json →
    Bundle Packaging (opa-bundle.tar.gz + manifest + sboms + provenance) →
      Signing / Attestations (cosign) → Registry / Release → Consumers pull & verify
```
Trust boundaries:

- B1: Contributor workstation → GitHub repo.
- B2: GitHub Actions workflow execution environment.
- B3: Storage / Release distribution (GitHub Releases, GHCR registry).
- B4: Consumer environment (clusters / pipelines verifying artifacts).


## 3. Threat Enumeration (STRIDE-Oriented per Stage)

| Stage | Threat Examples |
|-------|-----------------|
| Source (B1) | T: Tampering with metadata IDs; R: Malicious Rego; I: Inconsistent severity/tags. |
| Tooling (B2) | T: Build modifies generator; R: Script injection; I: Skipped validation yields incomplete index. |
| Generated Artifacts | T: Add/remove entries; R: Replay stale index; I: Hash truncation/collision attempts. |
| Distribution (B3) | T: Registry substitution / MITM; R: Replay old bundle; D: Large malicious policy set (DoS). |
| Consumer (B4) | T: Use unverified bundle; E: Skip provenance; I: Partial ingestion without alert. |


## 4. Existing Controls

| Control | Coverage |
|---------|----------|
| Git version control + code review | Source integrity & traceability |
| Guardrails scripts (metadata, links, tests) | Reduce malformed / risky content |
| Rego test enforcement | Deny/pass presence regression safety |
| Deterministic generation script | Predictable diff-based review |
| Bundle manifest (hash list + aggregate) | Post-build tamper detection |
| Cosign signatures | Distribution authenticity & integrity |
| SBOM generation | Component transparency |
| (Planned) Provenance attestation | Build identity & material linkage |

## 5. Gaps & Risks

| Gap | Impact | Priority |
|-----|--------|----------|
| Lack of explicit freshness / timestamp check on consumer side | Replay of old but validly signed bundle | Medium |
| No policy for minimum test coverage vs deny rules enforced at release gate | Logic modifications slipping | Medium |
| Incomplete provenance adoption for all artifacts (only bundle) | Reduced traceability for index-only consumers | Medium |
| No automated ID collision detector across historical releases | Potential confusion / override risk | Low |
| Absence of reproducible build assertion (no secondary build compare) | Harder to detect compromised build runner | Low |
| Metadata field normalization (tags/geo) partially manual | Inconsistent semantics to consumers | Low |

## 6. Recommended Mitigations & Roadmap

Short term (1–2 releases):

- Consumer guidance: document verification workflow (provenance + freshness check).
- Add Make target `verify-index` to recompute & compare `dist/index.json` vs sources + manifest.
- Enforce aggregate test gate (deny rules >1 must have aggregate test).

Mid term (2–4 releases):

- Extend provenance predicate to include `dist/index.json` hash.
- Introduce release metadata file (policy count & index SHA) signed separately.
- Implement ID collision scanner (new index vs previous tag; fail on conflicting reuse).
- Add evaluation performance budget metric (detect pathologic Rego growth).

Long term:

- Reproducible build: secondary ephemeral rebuild to compare hashes.
- Continuous attestation monitoring (Rekor scanning / mismatch alerts).
- Policy-level provenance (source digest → packaged path mapping).

## 7. Attack Scenarios & Mitigations

| Scenario | Description | Mitigations |
|----------|-------------|-------------|
| Malicious contributor exfil rule | Exfil via trusted decision output | Review, deny/pass tests, future static scan |
| Build runner compromise | Phantom policies added / removed | Deterministic script + manifest + provenance |
| Replay (old bundle) | Outdated controls persist | Freshness policy, tag pinning, provenance timestamp check |
| Tampered distribution (MITM) | Bundle bytes modified | Cosign signature + manifest hash verification |
| Silent severity downgrade | Risk underestimated downstream | Release diff review, approval rule on severity lowers |
| Oversized pathological policy | Evaluation resource exhaustion | Complexity lint, performance gate |

## 8. Assurance & Monitoring Metrics

Suggested KPIs:

- Policy count delta vs prior release (expected vs actual)
- % policies with aggregate + negative tests
- Index generation time (baseline drift)
- Hash mismatches in verification job (target: 0)
- Provenance attestation availability rate

## 9. Consumer Verification Checklist (Quick Reference)

1. Download bundle + manifest + signatures (or pull OCI ref + referrers)
2. Verify cosign signatures with identity constraints
3. Verify provenance (builder ID, workflow path, subject digest matches bundle / manifest)
4. Recompute manifest aggregate hash locally; compare
5. Optionally regenerate `index.json` (checkout tag) and diff vs distributed file
6. Enforce freshness (approved tag; within policy schedule)
7. Monitor unexpected policy ID removals vs last baseline

## 10. Status Summary

| Property | Status |
|----------|--------|
| Integrity | Strong (bundle hash + signature); moderate for raw `index.json` sans manual verify |
| Authenticity | Cosign keyless + planned broader provenance |
| Completeness | Guardrails + deterministic gen; need automated cross-version diff |
| Traceability | Commit refs implicit; multi-subject provenance pending |
| Replay Resistance | Relies on consumer freshness policy |

---
This threat model is versioned implicitly via repository history; propose updates by submitting a PR.
