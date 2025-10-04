package rulehub.betting.market_restrictions_youth

# curated: use unrestricted market for allow
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.market_restrictions_youth": true}, "market": {"type": "professional_league"}}
}

test_denies_when_market_type_youth_league if {
	count(deny) > 0 with input as {"controls": {"betting.market_restrictions_youth": true}, "market": {"type": "youth_league"}}
}

test_denies_when_market_type_underage_event if {
	count(deny) > 0 with input as {"controls": {"betting.market_restrictions_youth": true}, "market": {"type": "underage_event"}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.market_restrictions_youth": false}, "market": {"type": "professional_league"}}
}

test_denies_when_market_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.market_restrictions_youth": false}, "market": {"type": "youth_league"}}
}

# Auto-generated granular test for controls["betting.market_restrictions_youth"]
test_denies_when_controls_betting_market_restrictions_youth_failing if {
	some _ in deny with input as {"controls": {"betting.market_restrictions_youth": false}, "market": {"type": "youth"}}
}
