package rulehub.betting.rtp_disclosure_to_players

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.rtp_disclosure_to_players": true}, "game": {"rtp_disclosed": true}}
}

test_denies_when_game_rtp_disclosed_false if {
	count(deny) > 0 with input as {"controls": {"betting.rtp_disclosure_to_players": true}, "game": {"rtp_disclosed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.rtp_disclosure_to_players": false}, "game": {"rtp_disclosed": true}}
}

test_denies_when_rtp_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.rtp_disclosure_to_players": false}, "game": {"rtp_disclosed": false}}
}

# Auto-generated granular test for controls["betting.rtp_disclosure_to_players"]
test_denies_when_controls_betting_rtp_disclosure_to_players_failing if {
	some _ in deny with input as {"controls": {"betting.rtp_disclosure_to_players": false}, "game": {"rtp_disclosed": true}}
}
