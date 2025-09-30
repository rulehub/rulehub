package rulehub.medtech.log_retention_for_clinical_events

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.log_retention_for_clinical_events": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"medtech.log_retention_for_clinical_events": false}}
}

# Evidence-based deny: retention days below policy minimum
test_denies_when_retention_below_minimum if {
	count(deny) > 0 with input as {"controls": {"medtech.log_retention_for_clinical_events": true}, "logs": {"retention_days": 30}, "policy": {"logs": {"min_retention_days": 90}}}
}

test_denies_when_control_disabled_and_retention_below_minimum if {
	count(deny) > 0 with input as {"controls": {"medtech.log_retention_for_clinical_events": false}, "logs": {"retention_days": 30}, "policy": {"logs": {"min_retention_days": 90}}}
}
