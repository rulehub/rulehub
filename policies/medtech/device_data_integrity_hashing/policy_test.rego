package rulehub.medtech.device_data_integrity_hashing

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.device_data_integrity_hashing": true}, "device": {"data": {"integrity_protection_enabled": true}}}
}

test_denies_when_device_data_integrity_protection_enabled_false if {
	count(deny) > 0 with input as {"controls": {"medtech.device_data_integrity_hashing": true}, "device": {"data": {"integrity_protection_enabled": false}}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.device_data_integrity_hashing": false}, "device": {"data": {"integrity_protection_enabled": true}}}
}

# Edge case: Both integrity protection disabled and control disabled
test_denies_when_both_integrity_false_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.device_data_integrity_hashing": false}, "device": {"data": {"integrity_protection_enabled": false}}}
}

# Additional Phase1 assertion: missing integrity field should deny
test_additional_denies_when_integrity_field_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.device_data_integrity_hashing": false}, "device": {"data": {"integrity_protection_enabled": true}}}
}
