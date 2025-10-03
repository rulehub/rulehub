package rulehub.igaming.self_exclusion_uk_gamstop

# curated: include player.self_excluded trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"igaming.self_exclusion_uk_gamstop": true}, "player": {"self_excluded": true}, "session": {"blocked": true}}
}

test_denies_when_session_blocked_false if {
	count(deny) > 0 with input as {"controls": {"igaming.self_exclusion_uk_gamstop": true}, "player": {"self_excluded": true}, "session": {"blocked": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_uk_gamstop": false}, "player": {"self_excluded": true}, "session": {"blocked": true}}
}

test_denies_when_player_self_excluded_but_not_blocked_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_uk_gamstop": false}, "player": {"self_excluded": true}, "session": {"blocked": false}}
}

# Auto-generated granular test for controls["betting.self_exclusion_uk_gamstop"]
test_denies_when_controls_betting_self_exclusion_uk_gamstop_failing if {
	some _ in deny with input as {"controls": {}, "player": {"self_excluded": true}, "controls[\"betting": {"self_exclusion_uk_gamstop\"]": false}}
}
