package rulehub.betting.self_exclusion_on_igaming

# curated

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.self_exclusion_on_igaming": true}, "player": {"on_self_excluded": false}, "session": {"blocked": true}}
}

test_denies_when_session_blocked_false if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_on_igaming": true}, "player": {"on_self_excluded": true}, "session": {"blocked": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_on_igaming": false}, "player": {"on_self_excluded": false}, "session": {"blocked": true}}
}

test_denies_when_player_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_on_igaming": false}, "player": {"on_self_excluded": true}, "session": {"blocked": false}}
}

# Auto-generated granular test for controls["betting.self_exclusion_on_igaming"]
test_denies_when_controls_betting_self_exclusion_on_igaming_failing if {
	some _ in deny with input as {"controls": {"betting.self_exclusion_on_igaming": false}, "player": {"on_self_excluded": true}}
}
