package rulehub.medtech.eu_mdr_pms_psur

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.eu_mdr_pms_psur": true}, "mdr": {"pms_plan": true, "psur_prepared": true}}
}

test_denies_when_mdr_pms_plan_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_pms_psur": true}, "mdr": {"pms_plan": false, "psur_prepared": true}}
}

test_denies_when_mdr_psur_prepared_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_pms_psur": true}, "mdr": {"pms_plan": true, "psur_prepared": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_pms_psur": false}, "mdr": {"pms_plan": true, "psur_prepared": true}}
}

# Edge case: Both MDR conditions false
test_denies_when_both_mdr_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_pms_psur": true}, "mdr": {"pms_plan": false, "psur_prepared": false}}
}
