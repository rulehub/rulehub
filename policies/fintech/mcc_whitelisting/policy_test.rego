package rulehub.fintech.mcc_whitelisting

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.mcc_whitelisting": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.mcc_whitelisting": false}}
}
