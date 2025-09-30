package rulehub.legaltech.ccpa_verification_of_requests

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.ccpa_verification_of_requests": true}, "ccpa": {"request_verified": true}}
}

test_denies_when_ccpa_request_verified_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.ccpa_verification_of_requests": true}, "ccpa": {"request_verified": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.ccpa_verification_of_requests": false}, "ccpa": {"request_verified": true}}
}

# Edge case: control disabled and request not verified
test_denies_when_control_disabled_and_request_not_verified if {
	count(deny) > 0 with input as {"controls": {"legaltech.ccpa_verification_of_requests": true}, "ccpa": {"request_verified": false}}
}
