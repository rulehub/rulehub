package rulehub.medtech.eu_mdr_eudamed_registration

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.eu_mdr_eudamed_registration": true}, "mdr": {"eudamed_registered": true}}
}

test_denies_when_mdr_eudamed_registered_false if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_eudamed_registration": true}, "mdr": {"eudamed_registered": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_eudamed_registration": false}, "mdr": {"eudamed_registered": true}}
}

# Edge case: Both EUDAMED not registered and control disabled
test_denies_when_both_registered_false_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.eu_mdr_eudamed_registration": false}, "mdr": {"eudamed_registered": false}}
}
