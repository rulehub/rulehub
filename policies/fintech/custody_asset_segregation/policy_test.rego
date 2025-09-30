package rulehub.fintech.custody_asset_segregation

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.custody_asset_segregation": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.custody_asset_segregation": false}}
}
