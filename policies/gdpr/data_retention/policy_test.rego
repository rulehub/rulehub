package rulehub.gdpr.data_retention

test_allow_when_compliant if {
	allow with input as {"controls": {"gdpr.data_retention": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"gdpr.data_retention": false}}
}
