package rulehub.legaltech.pipeda_ca_consent

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.pipeda_ca_consent": true}, "pipeda": {"consent_obtained": true}}
}

test_denies_when_pipeda_consent_obtained_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.pipeda_ca_consent": true}, "pipeda": {"consent_obtained": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.pipeda_ca_consent": false}, "pipeda": {"consent_obtained": true}}
}

test_denies_when_control_disabled_and_consent_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.pipeda_ca_consent": false}, "pipeda": {"consent_obtained": false}}
}

# Auto-generated granular test for controls["legaltech.pipeda_ca_consent"]
test_denies_when_controls_legaltech_pipeda_ca_consent_failing if {
	some _ in deny with input as {"controls": {}, "pipeda": {"consent_obtained": true}, "controls[\"legaltech": {"pipeda_ca_consent\"]": false}}
}
