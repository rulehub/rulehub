package rulehub.fintech.chargeback_monitoring

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.chargeback_monitoring": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.chargeback_monitoring": false}}
}
