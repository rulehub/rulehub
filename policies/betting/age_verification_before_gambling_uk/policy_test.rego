package rulehub.betting.age_verification_before_gambling_uk

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.age_verification_before_gambling_uk": true}, "kyc": {"age_verified": true}}
}

test_denies_when_kyc_age_verified_false if {
	count(deny) > 0 with input as {"controls": {"betting.age_verification_before_gambling_uk": true}, "kyc": {"age_verified": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.age_verification_before_gambling_uk": false}, "kyc": {"age_verified": true}}
}

# Additional deny-focused case: unverified age with control enabled
test_denies_when_age_unverified_and_control_enabled if {
	count(deny) > 0 with input as {"controls": {"betting.age_verification_before_gambling_uk": true}, "kyc": {"age_verified": false}}
}
