package rulehub.fintech.cold_storage_ratio

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.cold_storage_ratio": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.cold_storage_ratio": false}}
}
