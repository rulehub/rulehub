package rulehub.betting.game_rules_visible_before_play

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.game_rules_visible_before_play": true}, "game": {"rules_visible": true}}
}

test_denies_when_game_rules_visible_false if {
	count(deny) > 0 with input as {"controls": {"betting.game_rules_visible_before_play": true}, "game": {"rules_visible": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.game_rules_visible_before_play": false}, "game": {"rules_visible": true}}
}

# Extra deny-focused test: ensure deny when rules are not visible
test_denies_when_rules_not_visible_extra if {
	count(deny) > 0 with input as {"controls": {"betting.game_rules_visible_before_play": true}, "game": {"rules_visible": false}}
}

# Auto-generated granular test for controls["betting.game_rules_visible_before_play"]
test_denies_when_controls_betting_game_rules_visible_before_play_failing if {
	some _ in deny with input as {"controls": {"betting.game_rules_visible_before_play": false}, "game": {"rules_visible": true}}
}
