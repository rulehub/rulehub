package rulehub.fintech.psd2_transaction_risk_analysis

# curated: deny requires control flag false + sca_passed false
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.psd2_transaction_risk_analysis": true}, "transaction": {"sca_passed": true}}
}

test_denies_when_transaction_sca_passed_false if {
	count(deny) > 0 with input as {"controls": {"fintech.psd2_transaction_risk_analysis": false}, "transaction": {"sca_passed": false}}
}
