package rulehub.betting.license_check_adm_it

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.license_check_adm_it": true}, "operator": {"licensed": true}}
}

test_denies_when_operator_licensed_false if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_adm_it": true}, "operator": {"licensed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_adm_it": false}, "operator": {"licensed": true}}
}

# Extra deny-focused test: operator not licensed
test_denies_when_operator_not_licensed_extra if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_adm_it": true}, "operator": {"licensed": false}}
}

# Auto-generated granular test for controls["betting.license_check_adm_it"]
test_denies_when_controls_betting_license_check_adm_it_failing if {
	some _ in deny with input as {"controls": {"betting.license_check_adm_it": false}, "operator": {"licensed": true}}
}
