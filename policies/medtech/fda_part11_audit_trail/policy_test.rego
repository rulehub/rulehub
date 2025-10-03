package rulehub.medtech.fda_part11_audit_trail

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.fda_part11_audit_trail": true}, "part11": {"audit_trail_enabled": true}}
}

test_denies_when_part11_audit_trail_enabled_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_audit_trail": true}, "part11": {"audit_trail_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_audit_trail": false}, "part11": {"audit_trail_enabled": true}}
}

# Edge case: Both audit trail disabled and control disabled
test_denies_when_both_audit_false_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_audit_trail": false}, "part11": {"audit_trail_enabled": false}}
}

# Auto-generated granular test for controls["medtech.fda_part11_audit_trail"]
test_denies_when_controls_medtech_fda_part11_audit_trail_failing if {
	some _ in deny with input as {"controls": {}, "part11": {"audit_trail_enabled": true}, "controls[\"medtech": {"fda_part11_audit_trail\"]": false}}
}
