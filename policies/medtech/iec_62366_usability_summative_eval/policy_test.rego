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

# Auto-generated granular test for controls["medtech.iec_62366_usability_summative_eval"]
test_denies_when_controls_medtech_iec_62366_usability_summative_eval_failing if {
	some _ in deny with input as {"controls": {}, "usability": {"summative_evaluation_done": true}, "controls[\"medtech": {"iec_62366_usability_summative_eval\"]": false}}
}
