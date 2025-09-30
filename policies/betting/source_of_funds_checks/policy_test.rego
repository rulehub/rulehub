package rulehub.betting.source_of_funds_checks

# curated: include high_spend trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.source_of_funds_checks": true}, "player": {"high_spend": true, "sof_collected": true}}
}

test_denies_when_player_sof_collected_false if {
	count(deny) > 0 with input as {"controls": {"betting.source_of_funds_checks": true}, "player": {"high_spend": true, "sof_collected": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.source_of_funds_checks": false}, "player": {"high_spend": false, "sof_collected": true}}
}

test_denies_when_high_spend_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.source_of_funds_checks": false}, "player": {"high_spend": true, "sof_collected": false}}
}
