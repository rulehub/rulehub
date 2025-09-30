package rulehub.betting.kyc_on_withdrawal

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.kyc_on_withdrawal": true}, "player": {"kyc_completed": true}}
}

test_denies_when_player_kyc_completed_false if {
	count(deny) > 0 with input as {"controls": {"betting.kyc_on_withdrawal": true}, "player": {"kyc_completed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.kyc_on_withdrawal": false}, "player": {"kyc_completed": true}}
}

# Extra deny-focused test: player not KYCed should deny
test_denies_when_player_not_kyc_extra if {
	count(deny) > 0 with input as {"controls": {"betting.kyc_on_withdrawal": true}, "player": {"kyc_completed": false}}
}
