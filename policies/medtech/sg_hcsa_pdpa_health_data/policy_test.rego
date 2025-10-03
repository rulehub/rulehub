package rulehub.medtech.sg_hcsa_pdpa_health_data

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.sg_hcsa_pdpa_health_data": true}, "pdpa": {"sg_purposes_specified": true}, "sg": {"hcsa": {"licence_valid": true}}}
}

test_denies_when_pdpa_sg_purposes_specified_false if {
	count(deny) > 0 with input as {"controls": {"medtech.sg_hcsa_pdpa_health_data": true}, "pdpa": {"sg_purposes_specified": false}, "sg": {"hcsa": {"licence_valid": true}}}
}

test_denies_when_sg_hcsa_licence_valid_false if {
	count(deny) > 0 with input as {"controls": {"medtech.sg_hcsa_pdpa_health_data": true}, "pdpa": {"sg_purposes_specified": true}, "sg": {"hcsa": {"licence_valid": false}}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.sg_hcsa_pdpa_health_data": false}, "pdpa": {"sg_purposes_specified": true}, "sg": {"hcsa": {"licence_valid": true}}}
}

# Edge case: Both PDPA and SG HCSA conditions false
test_denies_when_both_pdpa_sg_false if {
	count(deny) > 0 with input as {"controls": {"medtech.sg_hcsa_pdpa_health_data": true}, "pdpa": {"sg_purposes_specified": false}, "sg": {"hcsa": {"licence_valid": false}}}
}

# Auto-generated granular test for controls["medtech.sg_hcsa_pdpa_health_data"]
test_denies_when_controls_medtech_sg_hcsa_pdpa_health_data_failing if {
	some _ in deny with input as {"controls": {}, "pdpa": {"sg_purposes_specified": true}, "sg": {"hcsa": {"licence_valid": true}}, "controls[\"medtech": {"sg_hcsa_pdpa_health_data\"]": false}}
}
