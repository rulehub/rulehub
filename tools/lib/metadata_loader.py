from __future__ import annotations

import os
from pathlib import Path
from typing import Any, Dict, List, Tuple

import yaml


# Internal in‑process cache. Keyed by absolute root directory path.
# Value: { 'snapshot': [(path, mtime, size), ...], 'data': List[(policy_id, Path, dict)] }
_CACHE: Dict[str, Dict[str, Any]] = {}
_CACHE_STATS: Dict[str, int] = {"hits": 0, "misses": 0}


def _build_snapshot(root: Path) -> List[Tuple[str, float, int]]:
    """Return a deterministic snapshot of metadata.yaml files under root.

    Each entry: (absolute_path, mtime, size). Sorted for stable comparison.
    """
    snap: List[Tuple[str, float, int]] = []
    for meta in root.rglob("metadata.yaml"):
        try:
            stat = meta.stat()
        except OSError:  # file disappeared
            continue
        snap.append((str(meta.resolve()), stat.st_mtime, stat.st_size))
    snap.sort()
    return snap


def invalidate_metadata_cache(root_dir: str | None = None) -> None:
    """Invalidate cache for a given root directory (or all if None)."""
    if root_dir is None:
        _CACHE.clear()
        return
    _CACHE.pop(str(Path(root_dir).resolve()), None)


def get_metadata_cache_stats() -> Dict[str, int]:  # pragma: no cover - trivial
    """Return a copy of cache hit/miss counters."""
    return dict(_CACHE_STATS)


def load_all_metadata(root_dir: str = "policies", use_cache: bool = True) -> List[Tuple[str, Path, dict]]:
    """Load all metadata.yaml files under root_dir with lightweight caching.

    Args:
        root_dir: Directory to scan recursively for metadata.yaml files.
        use_cache: If True (default) re-use an in-process cache when the
            file snapshot (paths + mtimes + sizes) is unchanged. Can be
            disabled per-call or globally via env RULEHUB_METADATA_CACHE=0.

    Returns: list[(policy_id, Path, data_dict)] skipping unparsable / non-dict.

    Invalidation strategy:
        - On each call we build a cheap snapshot of (path, mtime, size).
        - If snapshot differs from cached snapshot for the root, we reload.
        - Explicit invalidation: call invalidate_metadata_cache(root_dir) or
          set RULEHUB_METADATA_CACHE=0 to bypass cache entirely.
    """
    abs_root = str(Path(root_dir).resolve())
    if os.environ.get("RULEHUB_METADATA_CACHE") == "0":  # forced disable
        use_cache = False

    root_path = Path(root_dir)
    snapshot = _build_snapshot(root_path)
    if use_cache:
        cached = _CACHE.get(abs_root)
        if cached and cached.get("snapshot") == snapshot:
            _CACHE_STATS["hits"] += 1
            # Return a shallow copy to avoid accidental caller mutation of cache list
            return list(cached["data"])  # type: ignore
    # (re)load
    out: List[Tuple[str, Path, dict]] = []
    for meta_path_str, _mtime, _size in snapshot:
        meta = Path(meta_path_str)
        try:
            data = yaml.safe_load(meta.read_text(encoding="utf-8")) or {}
        except Exception:
            continue
        if isinstance(data, dict):
            pid = data.get("id") or meta.parent.name
            out.append((pid, meta, data))
    if use_cache:
        _CACHE[abs_root] = {"snapshot": snapshot, "data": out}
        _CACHE_STATS["misses"] += 1
    return list(out)
