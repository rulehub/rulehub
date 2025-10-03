package rulehub.medtech.ca_phipa_health_data

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.ca_phipa_health_data": true}, "phipa": {"safeguards_implemented": true}}
}

test_denies_when_phipa_safeguards_implemented_false if {
	count(deny) > 0 with input as {"controls": {"medtech.ca_phipa_health_data": true}, "phipa": {"safeguards_implemented": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.ca_phipa_health_data": false}, "phipa": {"safeguards_implemented": true}}
}

# Edge case: Both safeguards not implemented and control disabled
test_denies_when_both_safeguards_false_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.ca_phipa_health_data": false}, "phipa": {"safeguards_implemented": false}}
}

# Additional Phase1 assertion: missing safeguards value triggers deny
test_additional_denies_when_safeguards_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.ca_phipa_health_data": false}, "phipa": {"safeguards_implemented": true}}
}

# Auto-generated granular test for controls["medtech.ca_phipa_health_data"]
test_denies_when_controls_medtech_ca_phipa_health_data_failing if {
	some _ in deny with input as {"controls": {}, "phipa": {"safeguards_implemented": true}, "controls[\"medtech": {"ca_phipa_health_data\"]": false}}
}
