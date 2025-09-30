package rulehub.betting.source_of_funds_thresholds

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.source_of_funds_thresholds": true}, "player": {"sof_collected": true}}
}

test_denies_when_player_sof_collected_false if {
	count(deny) > 0 with input as {"controls": {"betting.source_of_funds_thresholds": true}, "player": {"sof_collected": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.source_of_funds_thresholds": false}, "player": {"sof_collected": true}}
}

test_denies_when_sof_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.source_of_funds_thresholds": false}, "player": {"sof_collected": false}}
}
