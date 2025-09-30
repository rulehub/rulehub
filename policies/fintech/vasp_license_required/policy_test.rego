package rulehub.fintech.vasp_license_required

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.vasp_license_required": true}, "crypto": {"licensing_compliant": true}}
}

test_denies_when_crypto_licensing_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.vasp_license_required": true}, "crypto": {"licensing_compliant": false}}
}
