package rulehub.betting.license_check_anj_fr

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.license_check_anj_fr": true}, "operator": {"licensed": true}}
}

test_denies_when_operator_licensed_false if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_anj_fr": true}, "operator": {"licensed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_anj_fr": false}, "operator": {"licensed": true}}
}

# Additional deny-focused test: operator missing licence
test_denies_when_operator_missing_license_extra if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_anj_fr": true}, "operator": {"licensed": false}}
}
