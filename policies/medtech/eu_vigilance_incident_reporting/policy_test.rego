package rulehub.medtech.eu_vigilance_incident_reporting

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.eu_vigilance_incident_reporting": true}, "eu": {"vigilance": {"process_defined": true}}}
}

test_denies_when_eu_vigilance_process_defined_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_vigilance_incident_reporting": true}, "eu": {"vigilance": {"process_defined": false}}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_vigilance_incident_reporting": false}, "eu": {"vigilance": {"process_defined": true}}}
}

# Edge case: Both vigilance process not defined and control disabled
test_denies_when_both_process_false_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_vigilance_incident_reporting": false}, "eu": {"vigilance": {"process_defined": false}}}
}

# Additional Phase1 test: missing vigilance.process_defined should deny
test_additional_denies_when_vigilance_field_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_vigilance_incident_reporting": false}, "eu": {"vigilance": {"process_defined": true}}}
}

# Auto-generated granular test for controls["medtech.eu_vigilance_incident_reporting"]
test_denies_when_controls_medtech_eu_vigilance_incident_reporting_failing if {
	some _ in deny with input as {"controls": {}, "eu": {"vigilance": {"process_defined": true}}, "controls[\"medtech": {"eu_vigilance_incident_reporting\"]": false}}
}
