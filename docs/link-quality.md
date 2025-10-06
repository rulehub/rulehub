# Link Quality Pipeline

This document describes how RuleHub ensures that URL references in policy metadata
remain high quality, consistent, and trustworthy over time.

## Overview

Policies include a `links` array in their `metadata.yaml` with authoritative references
(laws, regulator guidance, standards, technical docs). Low‑quality or marketing links
can accumulate and reduce signal; the link quality pipeline detects and curates these
issues.

Core goals:

- Detect patterns that correlate with link rot, low signal, or vendor marketing bias.
- Highlight discrepancies between curated metadata links and an optional exported list (`links_export.json`).
- Provide guardrails in local dev, CI, and release workflows without creating excessive friction.
- Track drift over time via baselining and (future) historical metrics.

## Normalization

Before audit heuristics run, links may be normalized (separate script(s)) to ensure consistent string forms:

- Trim surrounding whitespace.
- Optionally lowercase the scheme + host (path/query preserved case).
- Remove obvious duplicate trailing slashes.
- De‑duplicate within a single policy while preserving original order (first occurrence kept).
- Future: strip benign tracking params (`utm_*`, `gclid`) during normalization rather than only flagging.

Normalization scripts (see `tools/normalize_links.py` and related helpers) are
idempotent and can be run safely multiple times.

## Audit Categories

`tools/analyze_links.py` performs a read‑only heuristic audit combining all metadata
links (and optionally those from an export file). Suspicious categories:

<!-- markdownlint-disable MD013 -->

| Category | Heuristic | Rationale |
|----------|-----------|-----------|
| non_https | URL starts with `http://` | Enforce transport security / modern sources |
| vendor | Host matches configured vendor/marketing domains (sportradar.com, emvco.com, styra.com, upguard.com) | Avoid biased / promotional sources unless intentionally allowed |
| tracking_query | Query contains tracking params (`utm_*`, `gclid`) | Reduce analytics noise / privacy concerns |
| celex_pdf | Contains `TXT/PDF` (EU law CELEX printable PDF indicator) | Printed/PDF citations often less stable than HTML canonical forms |
| long | Length > 180 characters | Very long URLs are brittle / may include session or tracking tokens |
| external_source_code | Host is raw.githubusercontent.com / gist.github.com or URL ends with archive extension (.zip, .tar.gz, .tgz, .tar, .tar.bz2, .tar.xz) | Elevated supply chain / integrity risk; prefer stable documentation pages over raw source blobs |
| highly_shared | Same exact URL referenced by >50 policies | Potential over‑reliance; maybe consolidate description or cite canonical root |

Each suspicious list is unique + sorted. "Highly shared" is emitted as a top list (capped at 50 entries) with counts.

## Baseline Comparison

A baseline file `links_audit_baseline.json` (if present) captures an accepted snapshot
of suspicious findings + discrepancies at a point in time. The flow:

1. Run `make link-audit` (invokes `analyze_links.py`).
2. Generate `links_audit_report.json` (using `--json`).
3. Run `make link-audit-diff` (script `tools/compare_links_baseline.py`) to diff current report vs baseline.
4. Output per-category Added / Removed counts and overall drift summary (always exit 0 unless `FAIL_LINK_AUDIT=1`).

Purpose: protect against silent growth of low-quality links while allowing intentional improvements to shrink the set.

To refresh baseline deliberately: replace `links_audit_baseline.json` after review in a dedicated PR.

## Link Metrics & History

Historical drift is tracked via build artifacts instead of committing volatile CSV updates to git. This keeps the
repository noise‑free while still enabling time‑series analysis.

### Daily Capture (Artifact, Not Git)

The daily link audit workflow (see CI) performs:

1. Run `make link-audit` to (re)generate `links_audit_report.json` (suspicious categories + discrepancies).
2. Extract a single CSV line of summary counts (date plus category counts) and append/update an in‑memory
   `links_audit_history.csv` (idempotent - if a row for `YYYY-MM-DD` already exists it is not duplicated).
3. Upload the resulting `links_audit_history.csv` as an artifact named `links-audit-history` (retention ~30 days;
   adjust retention in workflow settings as needed). No commit is made to the repo.

CSV schema (daily raw history):

```csv
date,non_https,vendor,tracking_query,celex_pdf,long,highly_shared,external_source_code
2025-08-20,0,3,5,1,2,10,0
...
```

Rationale for "artifact not git":

- Avoid noisy churn in PRs (one line per day commit pollution).
- Allow automatic pruning via artifact retention instead of manual VCS hygiene.
- Keep repository focused on source truth (policies + maps) while metrics remain derived/ephemeral.

### Weekly Aggregation

On demand (locally or in a scheduled job) the script `tools/aggregate_link_history.py` consumes one or more downloaded
daily CSV artifacts (`links_audit_history*.csv`) and produces `links_audit_weekly.csv` summarizing by ISO week:

- `week_start` (Monday, ISO week anchor)
- `iso_year_week` (e.g., `2025-W34`)
- For each category: `sum_<cat>` and `avg_<cat>`

Example (abbreviated):

```csv
iso_year_week,week_start,sum_non_https,avg_non_https,sum_vendor,avg_vendor,...
2025-W34,2025-08-18,0,0.0,21,3.0,...
```

The weekly file can be used to drive charts or embedded tables in documentation (future enhancement: automated chart generation).

### Reconstructing History Locally

1. (Optional) List artifacts: `gh run list --workflow link-audit` then locate recent successful runs.
2. Download artifacts (repeat or use a small script):
   `gh run download <run-id> -n links-audit-history -D artifacts/<run-id>/`.
3. Collect all `artifacts/*/links_audit_history.csv` into one directory.
4. Run `python tools/aggregate_link_history.py --input-dir artifacts --output dist/links_audit_weekly.csv` (or `make link-audit-weekly`).
5. Inspect `dist/links_audit_weekly.csv` or import it into analysis/visualization tooling.

### Retention & Gaps

- Default artifact retention (30 days) creates a rolling window; to preserve long‑term trends periodically export
  weekly aggregates (or snapshot a baseline) into a permanent location (could be a dedicated `metrics/` branch or external storage).
- If a daily artifact is missing (workflow skipped/failing) aggregation naturally yields a lower `sum_*` for that week;
  gaps can be detected by missing calendar dates compared to expected range.
- Baseline + weekly trends together allow answering: "Did vendor links spike this month?" without storing every raw event.

### Integrity & Reproducibility

- All metrics are derivable from underlying link sets at any commit; artifacts are convenience accelerators, not a source of truth.
- The daily CSV values should strictly equal counts in `links_audit_report.json` for that day (guardrail: optional future validation step comparing the two before artifact upload).

### Security Considerations

- No external network calls are made in the metrics pipeline - counts are computed solely from repository metadata.
- Artifact tampering risk is low; for higher assurance, a future workflow could sign weekly aggregates and publish detached signatures.

### Summary

Use artifacts for ephemeral, append‑only daily metrics; aggregate when needed; keep git history clean; retain ability to recreate metrics from source at any point.

## Failure Modes & Env Flags

Environment flags influence guardrail strictness:

| Env Var | Effect |
|---------|--------|
| `FAIL_LINK_AUDIT=1` | Causes `analyze_links.py` (and diff script) to exit non‑zero (5) if any suspicious links or discrepancies are present. Without this flag audits are informational. |
| `STRICT_EMPTY_PATHS=1` | (Metadata path guardrail) Fails validation if any policy still has `path: []` placeholder. Related but not specific to links; included here for full pipeline context. |

<!-- markdownlint-enable MD013 -->

Default `make guardrails` run integrates a non‑failing link audit; CI or release flows
can enable strict mode via `FAIL_LINK_AUDIT=1` to block unexpected drift.

## Remediation Workflow

1. Run local audit: `make link-audit` (inspect summary & JSON report).
2. If new suspicious entries appear, triage:
   - Replace vendor / marketing pages with regulator or standard body primary sources.
   - Swap `http://` with `https://` if canonical resource supports HTTPS.
   - Remove tracking parameters or locate a clean canonical URL.
   - Replace CELEX PDF variant with stable HTML EUR-Lex page.
   - For long URLs, search for a shorter stable root document.
3. Update affected `metadata.yaml` `links` arrays.
4. Re-run audit until categories shrink / stabilize.
5. If intended residual findings remain (e.g., only available PDF), accept and update baseline in a controlled PR.

## Future Enhancements

Planned or potential improvements:

- Vendor allowlist / denylist file (`links_vendor_policies.json`) to explicitly permit
certain vendor documentation when necessary, suppressing noise.
<!-- external_source_code implemented; removed from future list -->
- Historical metrics file (`links_audit_history.csv`) appended daily to support trend charts in docs.
- Automatic normalization of benign tracking params instead of merely flagging.
- Severity scoring per URL aggregating multiple heuristic hits.
- Integration with release checklist (drift summary gate before tagging).

Contributions welcome: extend heuristics conservatively, keeping false positives low and reproducible (no network calls).
