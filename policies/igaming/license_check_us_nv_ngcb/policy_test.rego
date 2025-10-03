package rulehub.igaming.license_check_us_nv_ngcb

test_allow_when_compliant if {
	allow with input as {"controls": {"igaming.license_check_us_nv_ngcb": true}, "operator": {"licensed": true}}
}

test_denies_when_operator_licensed_false if {
	count(deny) > 0 with input as {"controls": {"igaming.license_check_us_nv_ngcb": true}, "operator": {"licensed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_us_nv_ngcb": false}, "operator": {"licensed": true}}
}

test_denies_when_operator_and_control_fail if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_us_nv_ngcb": false}, "operator": {"licensed": false}}
}

# Auto-generated granular test for controls["betting.license_check_us_nv_ngcb"]
test_denies_when_controls_betting_license_check_us_nv_ngcb_failing if {
	some _ in deny with input as {"controls": {}, "operator": {"licensed": true}, "controls[\"betting": {"license_check_us_nv_ngcb\"]": false}}
}
