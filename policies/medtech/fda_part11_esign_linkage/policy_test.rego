package rulehub.medtech.fda_part11_esign_linkage

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.fda_part11_esign_linkage": true}, "part11": {"esign_linked_to_record": true, "unique_ids": true}}
}

test_denies_when_part11_esign_linked_to_record_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_esign_linkage": true}, "part11": {"esign_linked_to_record": false, "unique_ids": true}}
}

test_denies_when_part11_unique_ids_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_esign_linkage": true}, "part11": {"esign_linked_to_record": true, "unique_ids": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_esign_linkage": false}, "part11": {"esign_linked_to_record": true, "unique_ids": true}}
}

# Edge case: Both Part11 conditions false
test_denies_when_both_part11_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_part11_esign_linkage": true}, "part11": {"esign_linked_to_record": false, "unique_ids": false}}
}
