package rulehub.aml.high_risk_country_edd

test_allow_when_compliant if {
	allow with input as {"controls": {"aml.high_risk_country_edd": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"aml.high_risk_country_edd": false}}
}
