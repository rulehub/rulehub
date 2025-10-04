package rulehub.betting.player_funds_segregation

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.player_funds_segregation": true}, "funds": {"segregated": true}}
}

test_denies_when_funds_segregated_false if {
	count(deny) > 0 with input as {"controls": {"betting.player_funds_segregation": true}, "funds": {"segregated": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.player_funds_segregation": false}, "funds": {"segregated": true}}
}

test_denies_when_funds_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.player_funds_segregation": false}, "funds": {"segregated": false}}
}

# Auto-generated granular test for controls["betting.player_funds_segregation"]
test_denies_when_controls_betting_player_funds_segregation_failing if {
	some _ in deny with input as {"controls": {"betting.player_funds_segregation": false}, "funds": {"segregated": true}}
}
