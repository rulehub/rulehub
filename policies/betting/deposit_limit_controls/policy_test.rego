package rulehub.betting.deposit_limit_controls

# curated: expanded evidence (limit enabled, applied, not exceeded)
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.deposit_limit_controls": true}, "limits": {"deposit_limit_enabled": true, "limit_exceeded": false, "limit_applied": true}}
}

test_denies_when_limit_exceeded_and_not_applied if {
	count(deny) > 0 with input as {"controls": {"betting.deposit_limit_controls": true}, "limits": {"deposit_limit_enabled": true, "limit_exceeded": true, "limit_applied": false}}
}

test_denies_when_deposit_limit_enabled_false if {
	count(deny) > 0 with input as {"controls": {"betting.deposit_limit_controls": true}, "limits": {"deposit_limit_enabled": false, "limit_exceeded": false, "limit_applied": true}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.deposit_limit_controls": false}, "limits": {"deposit_limit_enabled": true, "limit_exceeded": false, "limit_applied": true}}
}

# Extra deny-focused test: deposit limit enabled but exceeded; application missing
test_denies_when_limit_exceeded_and_not_applied_extra if {
	count(deny) > 0 with input as {"controls": {"betting.deposit_limit_controls": true}, "limits": {"deposit_limit_enabled": true, "limit_exceeded": true, "limit_applied": false}}
}

# Auto-generated granular test for controls["betting.deposit_limit_controls"]
test_denies_when_controls_betting_deposit_limit_controls_failing if {
	some _ in deny with input as {"controls": {}, "limits": {"deposit_limit_enabled": true, "limit_exceeded": true}, "controls[\"betting": {"deposit_limit_controls\"]": false}}
}
