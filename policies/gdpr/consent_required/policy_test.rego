package rulehub.gdpr.consent_required

test_allow_when_compliant if {
	allow with input as {"controls": {"gdpr.consent_required": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"gdpr.consent_required": false}}
}
