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

# Auto-generated granular test for controls["medtech.fda_mdr_event_reporting"]
test_denies_when_controls_medtech_fda_mdr_event_reporting_failing if {
	some _ in deny with input as {"controls": {}, "fda": {"mdr_reporting_process_defined": true}, "controls[\"medtech": {"fda_mdr_event_reporting\"]": false}}
}
