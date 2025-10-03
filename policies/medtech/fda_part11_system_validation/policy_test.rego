package rulehub.medtech.fda_part11_system_validation

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.fda_part11_system_validation": true}, "part11": {"validation_evidence_available": true}}
}

test_denies_when_part11_validation_evidence_available_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_system_validation": true}, "part11": {"validation_evidence_available": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_system_validation": false}, "part11": {"validation_evidence_available": true}}
}

# Edge case: Both validation evidence not available and control disabled
test_denies_when_both_evidence_false_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_system_validation": false}, "part11": {"validation_evidence_available": false}}
}

# Auto-generated granular test for controls["medtech.fda_part11_system_validation"]
test_denies_when_controls_medtech_fda_part11_system_validation_failing if {
	some _ in deny with input as {"controls": {}, "part11": {"validation_evidence_available": true}, "controls[\"medtech": {"fda_part11_system_validation\"]": false}}
}
