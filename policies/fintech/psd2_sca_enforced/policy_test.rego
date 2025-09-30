package rulehub.fintech.psd2_sca_enforced

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.psd2_sca_enforced": true}, "transaction": {"sca_passed": true}}
}

test_denies_when_transaction_sca_passed_false if {
	count(deny) > 0 with input as {"controls": {"fintech.psd2_sca_enforced": false}, "transaction": {"sca_passed": false}}
}
