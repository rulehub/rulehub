package rulehub.legaltech.gdpr_breach_72h

# curated: added breach.occurred context
test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_breach_72h": true}, "breach": {"occurred": true, "notified_supervisor_in_72h": true}}
}

test_denies_when_breach_notified_supervisor_in_72h_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_breach_72h": true}, "breach": {"occurred": true, "notified_supervisor_in_72h": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_breach_72h": false}, "breach": {"occurred": true, "notified_supervisor_in_72h": true}}
}

test_denies_when_breach_occurred_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_breach_72h": false}, "breach": {"occurred": true, "notified_supervisor_in_72h": false}}
}

# Auto-generated granular test for controls["legaltech.gdpr_breach_72h"]
test_denies_when_controls_legaltech_gdpr_breach_72h_failing if {
	some _ in deny with input as {"controls": {}, "breach": {"occurred": true}, "controls[\"legaltech": {"gdpr_breach_72h\"]": false}}
}
