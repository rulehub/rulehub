package rulehub.medtech.eu_mdr_ce_marking_and_udi

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.eu_mdr_ce_marking_and_udi": true}, "mdr": {"ce_marking": true, "udi_assigned": true}}
}

test_denies_when_mdr_ce_marking_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_ce_marking_and_udi": true}, "mdr": {"ce_marking": false, "udi_assigned": true}}
}

test_denies_when_mdr_udi_assigned_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_ce_marking_and_udi": true}, "mdr": {"ce_marking": true, "udi_assigned": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_ce_marking_and_udi": false}, "mdr": {"ce_marking": true, "udi_assigned": true}}
}

# Edge case: All MDR conditions false
test_denies_when_all_mdr_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_ce_marking_and_udi": true}, "mdr": {"ce_marking": false, "udi_assigned": false}}
}

# Auto-generated granular test for controls["medtech.eu_mdr_ce_marking_and_udi"]
test_denies_when_controls_medtech_eu_mdr_ce_marking_and_udi_failing if {
	some _ in deny with input as {"controls": {}, "mdr": {"ce_marking": true, "udi_assigned": true}, "controls[\"medtech": {"eu_mdr_ce_marking_and_udi\"]": false}}
}
