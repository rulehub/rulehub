package rulehub.fintech.kyc_biometric_liveness

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.kyc_biometric_liveness": true}, "kyc": {"liveness_passed": true}}
}

test_denies_when_kyc_liveness_passed_false if {
	count(deny) > 0 with input as {"controls": {"fintech.kyc_biometric_liveness": true}, "kyc": {"liveness_passed": false}}
}
