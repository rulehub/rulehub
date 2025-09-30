package rulehub.betting.no_bets_by_participants

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.no_bets_by_participants": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"betting.no_bets_by_participants": false}}
}

test_denies_when_participant_places_bet if {
	count(deny) > 0 with input as {
		"participant_role": "athlete",
		"bet": {"placed": true},
		"controls": {"betting.no_bets_by_participants": true},
	}
}

test_denies_when_participant_and_control_fail_extra if {
	count(deny) > 0 with input as {"participant_role": "coach", "bet": {"placed": true}, "controls": {"betting.no_bets_by_participants": false}}
}
