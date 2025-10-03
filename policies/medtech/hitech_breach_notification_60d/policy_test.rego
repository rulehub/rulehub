package rulehub.medtech.hitech_breach_notification_60d

# curated: include occurred + days_since trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.hitech_breach_notification_60d": true}, "breach": {"occurred": true, "days_since": 30, "notified": true}}
}

test_denies_when_breach_notified_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hitech_breach_notification_60d": true}, "breach": {"occurred": true, "days_since": 61, "notified": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hitech_breach_notification_60d": false}, "breach": {"occurred": false, "days_since": 30, "notified": true}}
}

test_denies_when_control_disabled_and_breach_unnotified_if_needed if {
	count(deny) > 0 with input as {"controls": {"medtech.hitech_breach_notification_60d": false}, "breach": {"occurred": true, "days_since": 61, "notified": false}}
}

# Auto-generated granular test for controls["medtech.hitech_breach_notification_60d"]
test_denies_when_controls_medtech_hitech_breach_notification_60d_failing if {
	some _ in deny with input as {"controls": {}, "breach": {"occurred": true}, "controls[\"medtech": {"hitech_breach_notification_60d\"]": false}}
}
