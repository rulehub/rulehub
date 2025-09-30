package rulehub.fintech.aml_account_freeze_on_hit

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_account_freeze_on_hit": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_account_freeze_on_hit": false}}
}
