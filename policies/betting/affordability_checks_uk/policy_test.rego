package rulehub.betting.affordability_checks_uk

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.affordability_checks_uk": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"betting.affordability_checks_uk": false}}
}

# Evidence-based deny: net deposits exceed affordability cap
test_denies_when_threshold_exceeded if {
	count(deny) > 0 with input as {"controls": {"betting.affordability_checks_uk": true}, "player": {"net_deposit_30d": 5000}, "affordability": {"max_30d": 3000}}
}

# Extra deny-focused test to ensure both deny branches are covered
test_denies_when_control_flag_false_and_threshold_ok if {
	count(deny) > 0 with input as {"controls": {"betting.affordability_checks_uk": false}, "player": {"net_deposit_30d": 100}, "affordability": {"max_30d": 3000}}
}
