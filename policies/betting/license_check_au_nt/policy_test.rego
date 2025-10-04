package rulehub.betting.license_check_au_nt

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.license_check_au_nt": true}, "operator": {"licensed": true}}
}

test_denies_when_operator_licensed_false if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_au_nt": true}, "operator": {"licensed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_au_nt": false}, "operator": {"licensed": true}}
}

# Additional deny-focused test: operator unlicensed triggers deny
test_denies_when_operator_unlicensed_extra if {
	count(deny) > 0 with input as {"controls": {"betting.license_check_au_nt": true}, "operator": {"licensed": false}}
}

# Auto-generated granular test for controls["betting.license_check_au_nt"]
test_denies_when_controls_betting_license_check_au_nt_failing if {
	some _ in deny with input as {"controls": {"betting.license_check_au_nt": false}, "operator": {"licensed": true}}
}
