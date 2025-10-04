package rulehub.betting.sanctions_screening_global

# curated: include sanctions.hit trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.sanctions_screening_global": true}, "sanctions": {"hit": true}, "account": {"blocked": true}}
}

test_denies_when_account_blocked_false if {
	count(deny) > 0 with input as {"controls": {"betting.sanctions_screening_global": true}, "sanctions": {"hit": true}, "account": {"blocked": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.sanctions_screening_global": false}, "sanctions": {"hit": false}, "account": {"blocked": true}}
}

test_denies_when_sanctions_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.sanctions_screening_global": false}, "sanctions": {"hit": true}, "account": {"blocked": false}}
}

# Auto-generated granular test for controls["betting.sanctions_screening_global"]
test_denies_when_controls_betting_sanctions_screening_global_failing if {
	some _ in deny with input as {"controls": {"betting.sanctions_screening_global": false}, "sanctions": {"hit": true}}
}
