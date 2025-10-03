# Performance & Scaling

## Baseline (Current Repository)

Measured via `python tools/coverage_map.py --profile`:

| Stage | Duration (s) | Notes |
|-------|--------------|-------|
| load_metadata_index | ~0.456 | YAML parsing + disk I/O (283 policies) |
| load_mappings | ~0.028 | Few compliance map YAML files |
| compute_policy_test_coverage | ~0.039 | Filesystem glob + existence checks |
| build_markdown | ~0.003 | String assembly only |
| build_mermaid | ~0.001 | Minimal graph text |
| write_json_outputs | ~0.066 | JSON + CSV serialization + path existence caching |
| total | ~0.594 | End-to-end generation |

Per-policy cost (dominant stage): ~0.456 s / 283 ≈ **1.61 ms** per policy metadata file.

## Projection: ×5 Policies (~1415)

Assuming near-linear scaling for metadata loading and negligible growth in constant stages:

```text
Projected metadata load ≈ 0.456 * 5 ≈ 2.28 s
Projected total ≈ (total - metadata) + projected_metadata ≈ (0.594 - 0.456) + 2.28 ≈ 2.42 s
Add 25% CI variance buffer ⇒ ≈ 3.0 s expected ceiling
```

## CI Metrics & Thresholds

A lightweight guard ensures performance regression detection:

1. Run `make perf-coverage` (invokes `tools/perf_check_coverage.py`).
2. Script parses `--profile` output; compares `total` against thresholds.
3. Environment variables:
   - `COVERAGE_MAX_SECONDS` (default 5.0) – hard fail (exit 5) if exceeded.
   - `COVERAGE_WARN_SECONDS` (default 75% of max) – soft warning (exit 3) if exceeded.
4. CI job marks build unstable (treat exit 3 as warn); blocks merge on exit 5.

Initial recommended settings:

- WARN: 3.75 s (default 0.75 * 5.0)
- FAIL: 5.00 s

These accommodate ×5 growth plus additional headroom for variance. Revisit once policy count approaches 1400 or if
refactors reduce baseline substantially.

## Future Optimizations (If Needed)

- Pre-load & cache YAML parse results to a serialized artifact keyed by file mtimes (incremental build).
- Batch file existence checks (already mitigated by `_path_exists` caching; could pre-stat via `os.scandir`).
- Parallel metadata parsing (multiprocessing) if single-core bottlenecks emerge (>5k policies).
- Optional skip of Mermaid / markdown for performance runs via a `--no-markdown` flag (not yet necessary).

## Interpreting Failures

If `perf-coverage` fails:

1. Inspect stage percentages; if a single stage >50% examine recent changes in that logic.
2. Confirm runner class (GitHub hosted vs local) to rule out environmental slowdown.
3. Consider raising thresholds only after justifying why optimization is impractical.

---

Generated & maintained manually; update when thresholds or architecture evolve.

## Index Pagination Plan (dist/index.json Chunking)

Goal: Prepare for future scale where `dist/index.json` (currently a single JSON with all `packages`) becomes large (memory & latency impact in Backstage plugin). Provide a backward compatible paging design requiring no immediate plugin changes, while enabling an opt‑in multi-file consumption path.

### Drivers

- JSON size growth: O(policy_count); at several thousand policies >1–2 MB may affect initial page load & caching.
- Differential fetch: allow clients to only pull needed segment(s) (e.g., lazy search index construction).
- Integrity: enable per-page hashing so partial corruption is detectable.

### Design Overview

Artifacts (new optional files alongside existing single file):

1. `dist/index.json` (UNCHANGED for compatibility) – still contains full `{"packages": [...]}` list.
2. `dist/index-pages.json` (manifest) – metadata describing paging set.
3. `dist/index-page-<n>.json` – individual page files containing a slice of packages array.

The paging artifacts are additive; existing consumers continue reading monolithic `index.json` until upgraded.

### Manifest Schema (index-pages.json)

```jsonc
{
   "schema": "rulehub.index.pages/1",
   "generated": "2025-08-27T12:34:56Z",        // ISO8601
   "total_packages": 1234,
   "page_size": 200,                            // target (last page may be smaller)
   "pages": [
      {
         "number": 1,
         "file": "index-page-1.json",
         "offset": 0,
         "count": 200,
         "sha256": "<hex>",
         "first_id": "aml.customer_due_diligence",
         "last_id":  "betting.underage_block"
      },
      { "number": 2, "file": "index-page-2.json", "offset": 200, "count": 200 }
   ],
   "aggregate": {
      "sha256_all": "<sha256(concatenated page sha256s or canonical re-serialization)>"
   },
   "monolith": {                                 // backlink + integrity for monolithic fallback file
      "file": "index.json",
      "sha256": "<hex>",
      "packages": 1234
   }
}
```

### Page File Schema (index-page-N.json)

```jsonc
{
   "schema": "rulehub.index.page/1",
   "page": 1,
   "page_size": 200,
   "total_pages": 7,
   "total_packages": 1234,
   "packages": [ { /* same package objects as monolith */ } ]
}
```

Package object remains unchanged to preserve plugin data contract.

### Ordering & Determinism

- Page ordering uses a stable sort by `id` (case-insensitive) to ensure consistent diffing and caching.
- Monolithic file may retain historical insertion order for now; future: optionally also sorted once consumers updated.

### Backward Compatibility Strategy

Phase 0 (Current): Only `index.json` produced.

Phase 1 (Additive – Proposed): Produce both monolith and paged set (flag `PAGED_INDEX=1` or
auto when `len(packages) > PAGE_THRESHOLD`). Plugin continues to read monolith; experimental
plugin reads manifest first if present.

Phase 2 (Opt-In Consumption): Document plugin upgrade path: try manifest → fall back to
monolith. Provide feature flag `USE_PAGED_INDEX` in plugin config.

Phase 3 (Future Optional): If size exceeds hard threshold (e.g., 5 MB), monolith may contain
only:

```jsonc
{ "schema": "rulehub.index.redirect/1", "manifest": "index-pages.json" }
```

Only after broad adoption; not planned yet.

### Integrity & Caching

- Each page individually hashable; CDN / HTTP caches can validate per-page ETag / checksum.
- Manifest records per-page hash enabling full set verification without loading all pages simultaneously (stream verify).
- Optional aggregated hash provides a single fingerprint for entire logical index (can be reproducible build target).

### Page Size Selection

- Default target: 200 packages per page (env `INDEX_PAGE_SIZE`). Balances ~50–150 KB compressed per
   page (estimate) vs request overhead.
- Hard minimum: 50 (avoid too many small requests). Hard maximum: 1000 (avoid large transfers defeating purpose).

### Generation Algorithm (Pseudo)

1. Build full list `packages` (existing logic) in memory.
2. If paging enabled (flag OR len > threshold):
    a. `sorted_packages = sorted(packages, key=lambda p: p['id'].lower())`.
    b. Chunk: for i in range(0, len(sorted_packages), page_size): write `index-page-{page}.json` with slice.
    c. Compute sha256 for each written page (streaming to avoid double memory use).
    d. Write manifest `index-pages.json`.
3. Always write monolithic `index.json` (fallback) unless Phase 3 redirect mode engaged.

### Client Consumption Flow (Plugin Upgrade)

1. Attempt fetch `index-pages.json`.
2. If 404 → load fallback monolithic `index.json`.
3. Else parse manifest, optionally validate `monolith.sha256` (defense-in-depth), then lazily fetch
   pages (e.g., first page for summary; others for search / detail view).
4. Optionally verify each page hash after download.

### Failure / Edge Cases

- Missing or corrupt page (hash mismatch): client can retry or fall back to monolith.
- Partial publish (manifest present but page absent): treat as error; display degraded mode using monolith if available.
- Page size change between runs: manifest `generated` timestamp + aggregate hash distinguish
   generations; clients should discard cached pages when manifest hash changes.

### Tooling Changes (Deferred / Not Implemented Yet)

- Extend `coverage_map.py` with new flags:
   - `--paged-index` (bool)
   - `--index-page-size N`
   - `--index-page-threshold N` (auto-enable if total > threshold)
- Helper function `write_paged_index(packages, out_dir) -> None` encapsulating logic.
   (Implementation intentionally deferred until a real size pressure occurs.)

### Migration Checklist

| Step | Action | Owner | Status |
|------|--------|-------|--------|
| 1 | Add plan (this document) | docs | DONE |
| 2 | Implement generator flags | tooling | TODO |
| 3 | Publish both formats | CI | TODO |
| 4 | Update Backstage plugin to prefer paged | plugin | TODO |
| 5 | Monitor size; decide Phase 3 | maintainers | FUTURE |

### Rationale Summary

This phased approach avoids breaking consumers, needs minimal code (one manifest writer + chunk
loop), and provides clear upgrade semantics with cryptographic integrity for each page.
