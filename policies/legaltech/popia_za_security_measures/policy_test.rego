package rulehub.legaltech.popia_za_security_measures

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.popia_za_security_measures": true}, "popia": {"security_measures_applied": true}}
}

test_denies_when_popia_security_measures_applied_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.popia_za_security_measures": true}, "popia": {"security_measures_applied": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.popia_za_security_measures": false}, "popia": {"security_measures_applied": true}}
}

test_denies_when_control_disabled_and_security_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.popia_za_security_measures": false}, "popia": {"security_measures_applied": false}}
}

# Auto-generated granular test for controls["legaltech.popia_za_security_measures"]
test_denies_when_controls_legaltech_popia_za_security_measures_failing if {
	some _ in deny with input as {"controls": {}, "popia": {"security_measures_applied": true}, "controls[\"legaltech": {"popia_za_security_measures\"]": false}}
}
