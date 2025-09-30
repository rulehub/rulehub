package rulehub.medtech.fda_mdr_event_reporting

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.fda_mdr_event_reporting": true}, "fda": {"mdr_reporting_process_defined": true}}
}

test_denies_when_fda_mdr_reporting_process_defined_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_mdr_event_reporting": true}, "fda": {"mdr_reporting_process_defined": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_mdr_event_reporting": false}, "fda": {"mdr_reporting_process_defined": true}}
}

# Edge case: Both MDR reporting process not defined and control disabled
test_denies_when_both_process_false_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_mdr_event_reporting": false}, "fda": {"mdr_reporting_process_defined": false}}
}
