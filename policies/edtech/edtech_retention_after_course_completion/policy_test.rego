package rulehub.edtech.edtech_retention_after_course_completion

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.edtech_retention_after_course_completion": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_retention_after_course_completion": false}}
}

test_denies_when_retention_exceeds_policy if {
	count(deny) > 0 with input as {
		"data": {"retention_days": 400},
		"policy": {"retention": {"max_days": 365}},
		"controls": {"edtech.edtech_retention_after_course_completion": true},
	}
}

test_denies_when_retention_exceeds_policy_and_control_disabled if {
	count(deny) > 0 with input as {
		"data": {"retention_days": 400},
		"policy": {"retention": {"max_days": 365}},
		"controls": {"edtech.edtech_retention_after_course_completion": false},
	}
}

# Auto-generated granular test for controls["edtech.edtech_retention_after_course_completion"]
test_denies_when_controls_edtech_edtech_retention_after_course_completion_failing if {
	some _ in deny with input as {"controls": {}, "data": {"retention_days": true}, "controls[\"edtech": {"edtech_retention_after_course_completion\"]": false}}
}
