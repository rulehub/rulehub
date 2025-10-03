package rulehub.legaltech.data_residency_requirements_enforced

# curated: include residency_required trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.data_residency_requirements_enforced": true}, "data": {"residency_required": true, "allowed_regions": ["eu-west-1"], "storage_region": "eu-west-1"}}
}

test_denies_when_data_storage_region_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.data_residency_requirements_enforced": true}, "data": {"residency_required": true, "allowed_regions": ["eu-west-1"], "storage_region": "us-east-1"}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.data_residency_requirements_enforced": false}, "data": {"residency_required": true, "allowed_regions": ["eu-west-1"], "storage_region": "eu-west-1"}}
}

test_denies_when_control_disabled_and_storage_outside_allowed if {
	count(deny) > 0 with input as {"controls": {"legaltech.data_residency_requirements_enforced": false}, "data": {"residency_required": true, "allowed_regions": ["eu-west-1"], "storage_region": "us-east-1"}}
}

# Auto-generated granular test for controls["legaltech.data_residency_requirements_enforced"]
test_denies_when_controls_legaltech_data_residency_requirements_enforced_failing if {
	some _ in deny with input as {"controls": {}, "data": {"residency_required": true}, "controls[\"legaltech": {"data_residency_requirements_enforced\"]": false}}
}
