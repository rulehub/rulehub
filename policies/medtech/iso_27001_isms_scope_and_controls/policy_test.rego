package rulehub.medtech.iso_27001_isms_scope_and_controls

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.iso_27001_isms_scope_and_controls": true}, "isms": {"controls_implemented": true, "scope_defined": true}}
}

test_denies_when_isms_controls_implemented_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_27001_isms_scope_and_controls": true}, "isms": {"controls_implemented": false, "scope_defined": true}}
}

test_denies_when_isms_scope_defined_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_27001_isms_scope_and_controls": true}, "isms": {"controls_implemented": true, "scope_defined": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_27001_isms_scope_and_controls": false}, "isms": {"controls_implemented": true, "scope_defined": true}}
}

# Edge case: Both ISMS conditions false
test_denies_when_both_isms_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_27001_isms_scope_and_controls": true}, "isms": {"controls_implemented": false, "scope_defined": false}}
}

# Auto-generated granular test for controls["medtech.iso_27001_isms_scope_and_controls"]
test_denies_when_controls_medtech_iso_27001_isms_scope_and_controls_failing if {
	some _ in deny with input as {"controls": {}, "isms": {"scope_defined": true, "controls_implemented": true}, "controls[\"medtech": {"iso_27001_isms_scope_and_controls\"]": false}}
}
