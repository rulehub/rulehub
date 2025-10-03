package rulehub.legaltech.gdpr_data_minimization

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_data_minimization": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_data_minimization": false}}
}

# Evidence-based deny: collected fields exceed necessary fields
test_denies_when_collecting_unnecessary_fields if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_data_minimization": true}, "data": {"collected_fields": 20, "necessary_fields": 5}}
}

test_denies_when_control_disabled_and_collecting_unnecessary_fields if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_data_minimization": false}, "data": {"collected_fields": 20, "necessary_fields": 5}}
}

# Auto-generated granular test for controls["legaltech.gdpr_data_minimization"]
test_denies_when_controls_legaltech_gdpr_data_minimization_failing if {
	some _ in deny with input as {"controls": {}, "data": {"collected_fields": true}, "controls[\"legaltech": {"gdpr_data_minimization\"]": false}}
}
