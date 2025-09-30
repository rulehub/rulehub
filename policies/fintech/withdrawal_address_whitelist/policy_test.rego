package rulehub.fintech.withdrawal_address_whitelist

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.withdrawal_address_whitelist": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.withdrawal_address_whitelist": false}}
}
