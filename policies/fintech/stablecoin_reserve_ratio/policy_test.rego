package rulehub.fintech.stablecoin_reserve_ratio

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.stablecoin_reserve_ratio": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.stablecoin_reserve_ratio": false}}
}
