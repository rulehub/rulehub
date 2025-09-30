package rulehub.edtech.au_ndb_breach_notification_edtech

# curated: include breach.eligible trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.au_ndb_breach_notification_edtech": true}, "breach": {"eligible": true, "notified": true}}
}

test_denies_when_eligible_and_not_notified if {
	count(deny) > 0 with input as {"controls": {"edtech.au_ndb_breach_notification_edtech": true}, "breach": {"eligible": true, "notified": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.au_ndb_breach_notification_edtech": false}, "breach": {"eligible": true, "notified": true}}
}

test_denies_when_breach_eligible_and_not_notified_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.au_ndb_breach_notification_edtech": false}, "breach": {"eligible": true, "notified": false}}
}
