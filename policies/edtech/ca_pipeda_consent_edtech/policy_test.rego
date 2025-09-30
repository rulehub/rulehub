package rulehub.edtech.ca_pipeda_consent_edtech

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.ca_pipeda_consent_edtech": true}, "pipeda": {"consent_obtained": true}}
}

test_denies_when_pipeda_consent_obtained_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ca_pipeda_consent_edtech": true}, "pipeda": {"consent_obtained": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ca_pipeda_consent_edtech": false}, "pipeda": {"consent_obtained": true}}
}

test_denies_when_consent_not_obtained_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ca_pipeda_consent_edtech": false}, "pipeda": {"consent_obtained": false}}
}
