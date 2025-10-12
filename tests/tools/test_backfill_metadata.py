import sys
from pathlib import Path
from typing import Any


# Import the backfill tool from tools/
MODULE_PATH = Path(__file__).resolve().parents[2] / "tools" / "backfill_metadata.py"
if str(MODULE_PATH.parent) not in sys.path:
    sys.path.insert(0, str(MODULE_PATH.parent))
import backfill_metadata as bf  # type: ignore[import-not-found]  # noqa: E402


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def read_yaml(path: Path) -> Any:
    from ruamel.yaml import YAML

    y = YAML()
    return y.load(path.read_text(encoding="utf-8"))


def test_backfill_dry_run_and_write(tmp_path: Path, monkeypatch: Any):
    # Arrange: policy with missing owner/tags/jurisdiction; .rego path to drive gatekeeper inference
    pol_dir = tmp_path / "policies" / "gdpr" / "data_minimization"
    write(pol_dir / "policy.rego", "package test\nallow { true }\n")
    write(
        pol_dir / "metadata.yaml",
        (
            "id: gdpr.data_minimization\n"
            "name: Data Minimization\n"
            "standard: GDPR\n"
            "version: '2016/679'\n"
            "path: policies/gdpr/data_minimization/policy.rego\n"
            "geo:\n"
            "  scope: EU\n"
            "owner: \n"
            "tags: []\n"
        ),
    )

    # Redirect policy root
    monkeypatch.setattr(bf, "POLICY_ROOT", tmp_path / "policies")

    # Dry run: should report updates but not modify file
    rc = bf.main(["--root", str(tmp_path / "policies")])
    assert rc == 0
    d1 = read_yaml(pol_dir / "metadata.yaml")
    assert (d1.get("owner") or "") == ""
    assert d1.get("tags") == []
    assert "jurisdiction" not in d1

    # Write mode: apply updates
    rc2 = bf.main(["--write", "--root", str(tmp_path / "policies")])
    assert rc2 == 0
    d2 = read_yaml(pol_dir / "metadata.yaml")
    assert d2.get("owner") == "compliance"  # gdpr -> compliance
    # tags should include domain and engine-derived tags
    assert set(d2.get("tags") or []) >= {"gdpr", "gatekeeper", "rego"}
    assert d2.get("jurisdiction") == ["EU"]


def test_backfill_preserves_existing_values(tmp_path: Path, monkeypatch: Any):
    pol_dir = tmp_path / "policies" / "k8s" / "host_network"
    write(pol_dir / "policy.rego", "package test\nallow { true }\n")
    write(
        pol_dir / "metadata.yaml",
        (
            "id: k8s.host_network\n"
            "name: Host Network Off\n"
            "standard: Kubernetes\n"
            "version: '1.x'\n"
            "path: policies/k8s/host_network/policy.rego\n"
            "owner: platform-security\n"  # pre-set
            "tags: [kubernetes, gatekeeper]\n"  # pre-set
            "jurisdiction: [Global]\n"  # pre-set
        ),
    )

    monkeypatch.setattr(bf, "POLICY_ROOT", tmp_path / "policies")
    rc = bf.main(["--write", "--root", str(tmp_path / "policies")])
    assert rc == 0
    d = read_yaml(pol_dir / "metadata.yaml")
    # existing preserved
    assert d.get("owner") == "platform-security"
    assert d.get("tags") == ["kubernetes", "gatekeeper"]
    assert d.get("jurisdiction") == ["Global"]
