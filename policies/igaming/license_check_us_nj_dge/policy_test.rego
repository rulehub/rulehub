package rulehub.igaming.license_check_us_nj_dge

test_allow_when_compliant if {
	allow with input as {"controls": {"igaming.license_check_us_nj_dge": true}, "operator": {"licensed": true}}
}

test_denies_when_operator_licensed_false if {
	count(deny) > 0 with input as {"controls": {"igaming.license_check_us_nj_dge": true}, "operator": {"licensed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_us_nj_dge": false}, "operator": {"licensed": true}}
}

test_denies_when_control_disabled_and_operator_unlicensed if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_us_nj_dge": false}, "operator": {"licensed": false}}
}
