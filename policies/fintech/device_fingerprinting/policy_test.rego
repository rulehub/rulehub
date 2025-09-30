package rulehub.fintech.device_fingerprinting

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.device_fingerprinting": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.device_fingerprinting": false}}
}
