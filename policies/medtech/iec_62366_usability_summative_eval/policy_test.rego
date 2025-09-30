package rulehub.medtech.iec_62366_usability_summative_eval

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.iec_62366_usability_summative_eval": true}, "usability": {"summative_evaluation_done": true}}
}

test_denies_when_usability_summative_evaluation_done_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62366_usability_summative_eval": true}, "usability": {"summative_evaluation_done": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62366_usability_summative_eval": false}, "usability": {"summative_evaluation_done": true}}
}

test_denies_when_control_disabled_and_summative_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62366_usability_summative_eval": false}, "usability": {"summative_evaluation_done": false}}
}

# Additional Phase1 assertion: undefined summative field should deny
test_additional_denies_when_summative_field_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62366_usability_summative_eval": false}, "usability": {"summative_evaluation_done": true}}
}
