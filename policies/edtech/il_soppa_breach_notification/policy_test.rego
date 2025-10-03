package rulehub.edtech.il_soppa_breach_notification

# curated: include breach.occurred trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.il_soppa_breach_notification": true}, "breach": {"occurred": true, "notified": true}}
}

test_denies_when_breach_notified_false if {
	count(deny) > 0 with input as {"controls": {"edtech.il_soppa_breach_notification": true}, "breach": {"occurred": true, "notified": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.il_soppa_breach_notification": false}, "breach": {"occurred": false, "notified": true}}
}

test_denies_when_breach_occurred_and_not_notified_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.il_soppa_breach_notification": false}, "breach": {"occurred": true, "notified": false}}
}

# Auto-generated granular test for controls["edtech.il_soppa_breach_notification"]
test_denies_when_controls_edtech_il_soppa_breach_notification_failing if {
	some _ in deny with input as {"controls": {}, "breach": {"occurred": true}, "controls[\"edtech": {"il_soppa_breach_notification\"]": false}}
}
