package rulehub.fintech.kyc_reverification_schedule

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.kyc_reverification_schedule": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.kyc_reverification_schedule": false}}
}
