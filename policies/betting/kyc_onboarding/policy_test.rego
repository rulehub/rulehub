package rulehub.betting.kyc_onboarding

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.kyc_onboarding": true}, "player": {"kyc_completed": true}}
}

test_denies_when_player_kyc_completed_false if {
	count(deny) > 0 with input as {"controls": {"betting.kyc_onboarding": true}, "player": {"kyc_completed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.kyc_onboarding": false}, "player": {"kyc_completed": true}}
}

# Extra deny-focused test: player missing KYC
test_denies_when_player_missing_kyc_extra if {
	count(deny) > 0 with input as {"controls": {"betting.kyc_onboarding": true}, "player": {"kyc_completed": false}}
}

# Auto-generated granular test for controls["betting.kyc_onboarding"]
test_denies_when_controls_betting_kyc_onboarding_failing if {
	some _ in deny with input as {"controls": {}, "player": {"kyc_completed": true}, "controls[\"betting": {"kyc_onboarding\"]": false}}
}
