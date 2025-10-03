package rulehub.legaltech.sa_pdpl_breach_notify

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.sa_pdpl_breach_notify": true}, "breach": {"notified": true, "severity": "serious"}}
}

test_denies_when_breach_notified_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.sa_pdpl_breach_notify": true}, "breach": {"notified": false, "severity": "serious"}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.sa_pdpl_breach_notify": false}, "breach": {"notified": true, "severity": "serious"}}
}

test_denies_when_control_disabled_and_breach_unnotified if {
	count(deny) > 0 with input as {"controls": {"legaltech.sa_pdpl_breach_notify": false}, "breach": {"notified": false, "severity": "serious"}}
}

# Auto-generated granular test for controls["legaltech.sa_pdpl_breach_notify"]
test_denies_when_controls_legaltech_sa_pdpl_breach_notify_failing if {
	some _ in deny with input as {"controls": {}, "breach": {"severity": true}, "controls[\"legaltech": {"sa_pdpl_breach_notify\"]": false}}
}
