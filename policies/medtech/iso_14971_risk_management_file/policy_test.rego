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
