package rulehub.aml.kyc_basic_cdd

test_allow_when_compliant if {
	allow with input as {"controls": {"aml.kyc_basic_cdd": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"aml.kyc_basic_cdd": false}}
}
