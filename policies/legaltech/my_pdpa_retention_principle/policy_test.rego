package rulehub.legaltech.my_pdpa_retention_principle

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.my_pdpa_retention_principle": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.my_pdpa_retention_principle": false}}
}

test_denies_when_retention_exceeds_max if {
	count(deny) > 0 with input as {
		"data": {"retention_days": 400},
		"policy": {"retention": {"max_days": 365}},
		"controls": {"legaltech.my_pdpa_retention_principle": true},
	}
}

test_denies_when_control_disabled_and_retention_exceeds_max if {
	count(deny) > 0 with input as {"controls": {"legaltech.my_pdpa_retention_principle": false}, "data": {"retention_days": 400}, "policy": {"retention": {"max_days": 365}}}
}
