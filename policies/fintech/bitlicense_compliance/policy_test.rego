package rulehub.fintech.bitlicense_compliance

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.bitlicense_compliance": true}, "crypto": {"licensing_compliant": true}}
}

test_denies_when_crypto_licensing_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.bitlicense_compliance": true}, "crypto": {"licensing_compliant": false}}
}
