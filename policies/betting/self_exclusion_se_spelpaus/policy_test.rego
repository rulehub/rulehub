package rulehub.betting.self_exclusion_se_spelpaus

# curated

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.self_exclusion_se_spelpaus": true}, "player": {"in_spelpaus": false}, "session": {"blocked": true}}
}

test_denies_when_session_blocked_false if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_se_spelpaus": true}, "player": {"in_spelpaus": true}, "session": {"blocked": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_se_spelpaus": false}, "player": {"in_spelpaus": false}, "session": {"blocked": true}}
}

test_denies_when_player_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_se_spelpaus": false}, "player": {"in_spelpaus": true}, "session": {"blocked": false}}
}

# Auto-generated granular test for controls["betting.self_exclusion_se_spelpaus"]
test_denies_when_controls_betting_self_exclusion_se_spelpaus_failing if {
	some _ in deny with input as {"controls": {}, "player": {"in_spelpaus": true}, "controls[\"betting": {"self_exclusion_se_spelpaus\"]": false}}
}
