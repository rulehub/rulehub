package rulehub.betting.license_check_gra_sg

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.license_check_gra_sg": true}, "operator": {"licensed": true}}
}

test_denies_when_operator_licensed_false if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_gra_sg": true}, "operator": {"licensed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_gra_sg": false}, "operator": {"licensed": true}}
}

test_denies_when_both_operator_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_gra_sg": false}, "operator": {"licensed": false}}
}

# Auto-generated granular test for controls["betting.license_check_gra_sg"]
test_denies_when_controls_betting_license_check_gra_sg_failing if {
	some _ in deny with input as {"controls": {"betting.license_check_gra_sg": false}, "operator": {"licensed": true}}
}
