package rulehub.fintech.aml_unusual_activity_alerting

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_unusual_activity_alerting": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_unusual_activity_alerting": false}}
}
