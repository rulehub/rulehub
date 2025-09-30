package rulehub.fintech.hot_wallet_limits

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.hot_wallet_limits": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.hot_wallet_limits": false}}
}
