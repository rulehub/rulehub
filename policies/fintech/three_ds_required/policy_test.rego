package rulehub.fintech.three_ds_required

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.three_ds_required": true}, "transaction": {"sca_passed": true}}
}

test_denies_when_transaction_sca_passed_false if {
	count(deny) > 0 with input as {"controls": {"fintech.three_ds_required": true}, "transaction": {"sca_passed": false}}
}
