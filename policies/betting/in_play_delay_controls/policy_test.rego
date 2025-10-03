package rulehub.betting.in_play_delay_controls

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.in_play_delay_controls": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"betting.in_play_delay_controls": false}}
}

test_denies_when_in_play_delay_below_minimum if {
	count(deny) > 0 with input as {
		"live_betting": {"enabled": true, "delay_ms": 1000},
		"policy": {"min_delay_ms": 2500},
		"controls": {"betting.in_play_delay_controls": true},
	}
}

# Extra deny-focused case: control disabled should deny
test_denies_when_control_disabled_extra if {
	count(deny) > 0 with input as {"controls": {"betting.in_play_delay_controls": false}, "live_betting": {"enabled": true, "delay_ms": 5000}, "policy": {"min_delay_ms": 1000}}
}

# Auto-generated granular test for controls["betting.in_play_delay_controls"]
test_denies_when_controls_betting_in_play_delay_controls_failing if {
	some _ in deny with input as {"controls": {}, "live_betting": {"enabled": true}, "controls[\"betting": {"in_play_delay_controls\"]": false}}
}
