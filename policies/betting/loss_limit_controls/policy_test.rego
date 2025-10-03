package rulehub.betting.loss_limit_controls

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.loss_limit_controls": true}, "limits": {"loss_limit_enabled": true}}
}

test_denies_when_limits_loss_limit_enabled_false if {
	count(deny) > 0 with input as {"controls": {"betting.loss_limit_controls": true}, "limits": {"loss_limit_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.loss_limit_controls": false}, "limits": {"loss_limit_enabled": true}}
}

test_denies_when_limits_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.loss_limit_controls": false}, "limits": {"loss_limit_enabled": false}}
}

# Auto-generated granular test for controls["betting.loss_limit_controls"]
test_denies_when_controls_betting_loss_limit_controls_failing if {
	some _ in deny with input as {"controls": {}, "limits": {"loss_limit_enabled": true}, "controls[\"betting": {"loss_limit_controls\"]": false}}
}
