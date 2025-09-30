<!-- markdownlint-disable MD013 -->
# Roadmap

> Living document outlining strategic themes and planned iterations. Focus: coverage transparency, scalable distribution, schema evolution, localization, integrity, and DX automation. Items are grouped by horizon; ordering inside each horizon is roughly priority. Status codes: PLANNING, DESIGN, IN PROGRESS, DONE, BACKLOG.

## Badge & Metrics Visibility

| Initiative | Description | Status | Target |
|------------|-------------|--------|--------|
| Policy Test Coverage Badge | Publish a badge reflecting % of policies with (a) deny tests and (b) aggregate tests for multi‑deny policies. Source: `dist/policy-test-coverage.json`. Short term: placeholder static badge; mid term: GitHub Action generates JSON -> shields static endpoint (gist or branch). | PLANNING | 0.2.x |
| Release Metrics Snapshot | `make metrics-capture` emits `dist/release-metrics.json` (policy_count, map_count, standards_count, map_version_count, timestamp, git_commit). Integrate into release notes & provenance attestations. | PLANNING | 0.2.x |
| Link Quality Trend Badge | Convert link audit daily CSV into weekly aggregates + badge (green if drift == 0). | BACKLOG | 0.3.x |

### Coverage Badge Implementation Plan

1. Generate coverage JSON (already produced / planned) during `make coverage`.
2. Add lightweight script to compute percentage(s) and emit `dist/policy-test-coverage-badge.json` of form `{ "schemaVersion":1, "label":"policy tests", "message":"87%", "color":"green" }` (shields static JSON schema).
3. Nightly workflow uploads artifact & (optionally) commits to a `badges/` branch or updates a gist.
4. README consumes badge via `https://img.shields.io/endpoint?url=<raw_json_url>`.

## Scalable Index Distribution

| Initiative | Description | Status | Target |
|------------|-------------|--------|--------|
| Chunked Index (Sharded) | When `dist/index.json` exceeds N packages (configurable), emit `dist/index-part-0001.json` etc. plus a root manifest with part count & hashes. Backwards compatibility: keep monolith until size threshold hit (e.g., 1 MB uncompressed). | DESIGN | 0.3.x |
| Paging Contract | Formalize optional query pattern for downstream consumers: load manifest → fetch parts (parallel). | DESIGN | 0.3.x |
| Integrity For Parts | Extend provenance + manifest to include per‑part hash list + aggregate hash (Merkle root candidate). | BACKLOG | 0.3.x |

### Chunked Index Notes

Approach: After metadata aggregation, if `len(packages) > max_items`, slice into deterministic stable ordering (sorted by id) to allow diff caching; manifest: `{ schemaVersion: 1, sharded: true, parts: [{file, sha256, packageCount}], aggregateHash }`.

## Compliance Map Evolution

| Initiative | Description | Status | Target |
|------------|-------------|--------|--------|
| Map Schema Versioning | Introduce `schema_version` field in each `compliance/maps/*.yml` to support structural evolution (e.g., attributes per section). Guardrail: fail if missing or unsupported. | PLANNING | 0.2.x |
| Section Metadata Enrichment | Optional fields: `jurisdiction`, `risk_level`, `notes`. Controlled vocab validated by schema. | BACKLOG | 0.3.x |
| Automated Version Bump Guardrail | Already partial: extend to detect schema version increments separate from content changes. | DESIGN | 0.2.x |

## Localization Pipeline

| Initiative | Description | Status | Target |
|------------|-------------|--------|--------|
| Translation File Layout | Adopt `translations/<lang>/<policy_id>.yaml` (status, description). Fallback to English if missing. | DONE | 0.1.x |
| Missing Translation Guardrail | `tools/check_missing_translations.py` to emit list; add threshold fail flag (e.g., `FAIL_MISSING_TRANSLATIONS=1`). | DESIGN | 0.2.x |
| i18n Coverage Badge | Percentage of policies translated per language (shields JSON endpoint). | BACKLOG | 0.3.x |
| Localization Workflow | GitHub Action generating POT‑like aggregate & opening PRs when new English strings appear. | BACKLOG | 0.3.x |

## Integrity & Supply Chain

| Initiative | Description | Status | Target |
|------------|-------------|--------|--------|
| Unified Integrity Script | `tools/verify_integrity_pipeline.py` to orchestrate bundle, manifest, provenance, signature, coverage metrics hash check. `make verify-all-integrity`. | PLANNING | 0.2.x |
| Aggregate Hash Canon | Define canonical sorted key hashing for multi‑file artifacts enabling quick drift detection. | DESIGN | 0.2.x |
| Policy SBOM (Source) | Generate SBOM for raw policy source and diff with bundle SBOM to detect build contamination. | BACKLOG | 0.3.x |
| Attestation Enrichment | Add release metrics & coverage summary to provenance predicate. | BACKLOG | 0.3.x |

## Performance & Scaling

| Initiative | Description | Status | Target |
|------------|-------------|--------|--------|
| Metadata Loader Caching | Implement file timestamp + content hash caching; auto‑invalidate on mtime change. | DONE | 0.1.x |
| Parallel Map & Metadata Parse | Use `concurrent.futures` for YAML parse when > threshold files; measure with timing wrapper. | PLANNING | 0.2.x |
| CI Performance Budget | Fail if coverage generation > X seconds (configurable) vs rolling baseline. | DESIGN | 0.3.x |

## Documentation Quality Automation

| Initiative | Description | Status | Target |
|------------|-------------|--------|--------|
| Examples Execution Harness | Execute fenced bash blocks marked `# example-test` safely (`make test-examples`). JSON report gating docs drift. | DESIGN | 0.2.x |
| Target Name Consistency Lint | Scan Markdown for `make <target>` names; verify they exist in `Makefile`. | BACKLOG | 0.3.x |
| Editorial Checklist | Standard style & verification list to apply in PR review template. | PLANNING | 0.2.x |

## Link Quality & History

| Initiative | Description | Status | Target |
|------------|-------------|--------|--------|
| Artifact-Only History | Move CSV history from git to artifacts (daily append) + weekly aggregator script. | DONE | 0.1.x |
| Weekly Aggregation | `tools/aggregate_link_history.py` to produce `links_audit_weekly.csv`. | PLANNING | 0.2.x |
| Drift Threshold Alerts | Fail guardrail when suspicious category count increases > % threshold. | BACKLOG | 0.3.x |

## Distribution & Consumption

| Initiative | Description | Status | Target |
|------------|-------------|--------|--------|
| Backstage Plugin Alignment | Maintain JSON shape & add compatibility notes when schema evolves (versioned). | ONGOING | Continuous |
| OCI Bundle Enhancements | Optional secondary index layer embedding coverage manifest to reduce parallel fetches. | BACKLOG | 0.3.x |

## High-Level Release Theme Targets

| Version (Planned) | Theme | Key Deliverables |
|-------------------|-------|------------------|
| 0.2.x | Transparency & Metrics | Coverage badge, roadmap publication, metrics capture, map schema versioning, integrity pipeline script. |
| 0.3.x | Scale & Sharding | Chunked index, parallel parsing, localization enhancements, weekly link aggregation. |
| 0.4.x | Distribution Hardening | Source SBOM diff, part integrity, performance budgets, CI gating metrics. |

## Non-Goals (Current Horizon)

- Inline policy execution engine (stays out of scope; focus is distribution & coverage metadata).
- Multi‑language (non‑Rego) policy transpilation.
- Proprietary regulation text storage (only references / links maintained).

## Contributing to the Roadmap

Open an issue labeled `roadmap` with: context, problem statement, proposed change, expected consumers, risk / mitigation. Pull Requests updating this file should group related changes & include rationale.

## Placeholder Coverage Badge

Current (placeholder): ![Policy Test Coverage](https://img.shields.io/badge/policy--test--coverage-TBD-lightgrey)

Will update once automated endpoint is live.

---

Last updated: {{ date }} (manual update required).
