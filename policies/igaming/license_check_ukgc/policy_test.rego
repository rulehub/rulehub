package rulehub.igaming.license_check_ukgc

test_allow_when_compliant if {
	allow with input as {"controls": {"igaming.license_check_ukgc": true}, "operator": {"licensed": true}}
}

test_denies_when_operator_licensed_false if {
	count(deny) > 0 with input as {"controls": {"igaming.license_check_ukgc": true}, "operator": {"licensed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_ukgc": false}, "operator": {"licensed": true}}
}

test_denies_when_control_disabled_and_operator_unlicensed if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_ukgc": false}, "operator": {"licensed": false}}
}
