package rulehub.legaltech.kr_pipa_breach_notification

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.kr_pipa_breach_notification": true}, "breach": {"notified": true, "severity": "serious"}}
}

test_denies_when_breach_notified_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.kr_pipa_breach_notification": true}, "breach": {"notified": false, "severity": "serious"}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.kr_pipa_breach_notification": false}, "breach": {"notified": true, "severity": "serious"}}
}

test_denies_when_control_disabled_and_breach_unnotified if {
	count(deny) > 0 with input as {"controls": {"legaltech.kr_pipa_breach_notification": false}, "breach": {"notified": false, "severity": "serious"}}
}

# Auto-generated granular test for controls["legaltech.kr_pipa_breach_notification"]
test_denies_when_controls_legaltech_kr_pipa_breach_notification_failing if {
	some _ in deny with input as {"controls": {}, "breach": {"severity": true}, "controls[\"legaltech": {"kr_pipa_breach_notification\"]": false}}
}
