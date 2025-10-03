package rulehub.medtech.eu_mdr_clinical_evaluation

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.eu_mdr_clinical_evaluation": true}, "mdr": {"clinical_eval_plan": true, "clinical_eval_report": true}}
}

test_denies_when_mdr_clinical_eval_plan_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_clinical_evaluation": true}, "mdr": {"clinical_eval_plan": false, "clinical_eval_report": true}}
}

test_denies_when_mdr_clinical_eval_report_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_clinical_evaluation": true}, "mdr": {"clinical_eval_plan": true, "clinical_eval_report": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_clinical_evaluation": false}, "mdr": {"clinical_eval_plan": true, "clinical_eval_report": true}}
}

# Edge case: Both MDR conditions false
test_denies_when_both_mdr_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_clinical_evaluation": true}, "mdr": {"clinical_eval_plan": false, "clinical_eval_report": false}}
}

# Auto-generated granular test for controls["medtech.eu_mdr_clinical_evaluation"]
test_denies_when_controls_medtech_eu_mdr_clinical_evaluation_failing if {
	some _ in deny with input as {"controls": {}, "mdr": {"clinical_eval_plan": true, "clinical_eval_report": true}, "controls[\"medtech": {"eu_mdr_clinical_evaluation\"]": false}}
}
