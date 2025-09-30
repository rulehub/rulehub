package rulehub.fintech.jwt_expiry_policy

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.jwt_expiry_policy": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.jwt_expiry_policy": false}}
}
