package rulehub.gdpr.data_minimization

test_allow_when_compliant if {
	allow with input as {"controls": {"gdpr.data_minimization": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"gdpr.data_minimization": false}}
}
