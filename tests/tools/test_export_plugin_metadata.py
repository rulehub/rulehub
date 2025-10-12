from typing import Any
from pathlib import Path

import yaml


def save_yaml_file(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")


def test_build_packages_derives_fields_and_coverage(tmp_path: Path) -> None:
    policies_root = tmp_path / "policies"
    maps_root = tmp_path / "compliance" / "maps"

    aml_meta: dict[str, Any] = {
        "id": "aml.pep_screening_required",
        "name": "<Name>",
        "standard": {"name": "<Standard or Regulation>", "version": '<version or "current">'},
        "geo": {"scope": "Global"},
        "industry": ["fintech", "gaming", ""],
    }
    save_yaml_file(policies_root / "aml" / "pep_screening_required" / "metadata.yaml", aml_meta)

    bet_meta: dict[str, Any] = {
        "id": "betting.ads_no_minors_targeting",
        "name": " ",
        "standard": {"name": " ", "version": " "},
        "jurisdiction": ["Global"],
        "industry": "gambling",
    }
    save_yaml_file(
        policies_root / "betting" / "ads_no_minors_targeting" / "metadata.yaml",
        bet_meta,
    )

    amld_map: dict[str, Any] = {
        "schema_version": 1,
        "regulation": "EU AMLD",
        "version": "5/6",
        "sections": {
            "1. AML": {
                "title": "AML Controls",
                "policies": ["aml.pep_screening_required"],
            }
        },
    }
    save_yaml_file(maps_root / "amld.yml", amld_map)

    betting_map: dict[str, Any] = {
        "schema_version": 1,
        "regulation": "Betting (multi-jurisdiction)",
        "version": "current",
        "sections": {
            "1. Market Integrity": {
                "title": "Integrity",
                "policies": ["betting.ads_no_minors_targeting"],
            }
        },
    }
    save_yaml_file(maps_root / "betting.yml", betting_map)

    from tools.export_plugin_metadata import build_packages

    data = build_packages(policies_root=policies_root, maps_root=maps_root)
    assert isinstance(data, dict) and "packages" in data
    pkgs = {p["id"]: p for p in data["packages"]}

    aml = pkgs["aml.pep_screening_required"]
    assert aml.get("name") == "Pep Screening Required"
    assert aml.get("standard") == "EU AMLD"
    assert aml.get("version") == "5/6"
    assert aml.get("jurisdiction") == ["Global"]
    assert "EU AMLD 5/6" in aml.get("coverage", [])
    # industry list should be preserved, cleaned and title-cased for display
    assert aml.get("industry") == ["FinTech", "Gaming"]

    bet = pkgs["betting.ads_no_minors_targeting"]
    assert bet.get("name") == "Ads No Minors Targeting"
    assert bet.get("standard") == "BETTING"
    assert bet.get("version") == "current"
    assert bet.get("jurisdiction") == ["Global"]
    assert "Betting (multi-jurisdiction) current" in bet.get("coverage", [])
    # industry string should be preserved and title-cased for display
    assert bet.get("industry") == "Gambling"


def test_industry_fallback_derivation(tmp_path: Path) -> None:
    policies_root = tmp_path / "policies"
    maps_root = tmp_path / "compliance" / "maps"

    # A medtech policy without explicit industry should derive "MedTech" (title-cased)
    med_meta: dict[str, Any] = {
        "id": "medtech.device_data_integrity_hashing",
        "name": "Device data integrity hashing",
        "standard": {"name": "IEC 62304", "version": "2006"},
        "geo": {"regions": ["Global"], "countries": ["*"], "scope": "Global"},
        "path": [
            "policies/medtech/device_data_integrity_hashing/policy.rego",
            "policies/medtech/device_data_integrity_hashing/policy_test.rego",
        ],
    }
    save_yaml_file(policies_root / "medtech" / "device_data_integrity_hashing" / "metadata.yaml", med_meta)

    from tools.export_plugin_metadata import build_packages

    data = build_packages(policies_root=policies_root, maps_root=maps_root)
    pkgs = {p["id"]: p for p in data["packages"]}
    med = pkgs["medtech.device_data_integrity_hashing"]
    assert med.get("industry") == "MedTech"
