package rulehub.medtech.iso_14971_risk_management_file

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.iso_14971_risk_management_file": true}, "risk": {"controls_traced": true, "file_exists": true}}
}

test_denies_when_risk_controls_traced_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_14971_risk_management_file": true}, "risk": {"controls_traced": false, "file_exists": true}}
}

test_denies_when_risk_file_exists_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_14971_risk_management_file": true}, "risk": {"controls_traced": true, "file_exists": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_14971_risk_management_file": false}, "risk": {"controls_traced": true, "file_exists": true}}
}

# Edge case: Both risk conditions false
test_denies_when_both_risk_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_14971_risk_management_file": true}, "risk": {"controls_traced": false, "file_exists": false}}
}

# Auto-generated granular test for controls["medtech.iso_14971_risk_management_file"]
test_denies_when_controls_medtech_iso_14971_risk_management_file_failing if {
	some _ in deny with input as {"controls": {}, "risk": {"file_exists": true, "controls_traced": true}, "controls[\"medtech": {"iso_14971_risk_management_file\"]": false}}
}
