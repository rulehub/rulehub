package rulehub.igaming.deposit_limit_controls

test_allow_when_compliant if {
	allow with input as {"controls": {"igaming.deposit_limit_controls": true}, "player": {"deposits": {"month_total": 500}}, "limits": {"monthly_max": 1000}}
}

test_denies_when_deposit_limit_exceeded if {
	count(deny) > 0 with input as {"controls": {"igaming.deposit_limit_controls": true}, "player": {"deposits": {"month_total": 1500}}, "limits": {"monthly_max": 1000}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"igaming.deposit_limit_controls": false}, "player": {"deposits": {"month_total": 500}}, "limits": {"monthly_max": 1000}}
}

test_denies_when_control_disabled_and_deposit_exceeded if {
	count(deny) > 0 with input as {"controls": {"igaming.deposit_limit_controls": false}, "player": {"deposits": {"month_total": 1500}}, "limits": {"monthly_max": 1000}}
}

# Auto-generated granular test for controls["igaming.deposit_limit_controls"]
test_denies_when_controls_igaming_deposit_limit_controls_failing if {
	some _ in deny with input as {"controls": {}, "player": {"deposits": {"month_total": true}}, "controls[\"igaming": {"deposit_limit_controls\"]": false}}
}
