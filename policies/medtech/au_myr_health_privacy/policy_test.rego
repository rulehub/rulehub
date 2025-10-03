package rulehub.medtech.au_myr_health_privacy

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.au_myr_health_privacy": true}, "mhr": {"access_controls": true, "security_measures": true}}
}

test_denies_when_mhr_access_controls_false if {
	count(deny) > 0 with input as {"controls": {"medtech.au_myr_health_privacy": true}, "mhr": {"access_controls": false, "security_measures": true}}
}

test_denies_when_mhr_security_measures_false if {
	count(deny) > 0 with input as {"controls": {"medtech.au_myr_health_privacy": true}, "mhr": {"access_controls": true, "security_measures": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.au_myr_health_privacy": false}, "mhr": {"access_controls": true, "security_measures": true}}
}

# Edge case: All MHR conditions false
test_denies_when_all_mhr_false if {
	count(deny) > 0 with input as {"controls": {"medtech.au_myr_health_privacy": true}, "mhr": {"access_controls": false, "security_measures": false}}
}

# Auto-generated granular test for controls["medtech.au_myr_health_privacy"]
test_denies_when_controls_medtech_au_myr_health_privacy_failing if {
	some _ in deny with input as {"controls": {}, "mhr": {"access_controls": true, "security_measures": true}, "controls[\"medtech": {"au_myr_health_privacy\"]": false}}
}
