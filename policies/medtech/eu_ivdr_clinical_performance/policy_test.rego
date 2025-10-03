package rulehub.medtech.eu_ivdr_clinical_performance

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.eu_ivdr_clinical_performance": true}, "ivdr": {"performance_evaluation_done": true}}
}

test_denies_when_ivdr_performance_evaluation_done_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_ivdr_clinical_performance": true}, "ivdr": {"performance_evaluation_done": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_ivdr_clinical_performance": false}, "ivdr": {"performance_evaluation_done": true}}
}

# Edge case: Both performance evaluation not done and control disabled
test_denies_when_both_performance_false_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_ivdr_clinical_performance": false}, "ivdr": {"performance_evaluation_done": false}}
}

# Additional assertion required by Phase 1: missing evaluation OR control flag should produce deny
test_additional_denies_when_missing_evaluation_or_control if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_ivdr_clinical_performance": false}, "ivdr": {"performance_evaluation_done": true}}
}

# Auto-generated granular test for controls["medtech.eu_ivdr_clinical_performance"]
test_denies_when_controls_medtech_eu_ivdr_clinical_performance_failing if {
	some _ in deny with input as {"controls": {}, "ivdr": {"performance_evaluation_done": true}, "controls[\"medtech": {"eu_ivdr_clinical_performance\"]": false}}
}
