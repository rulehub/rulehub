package rulehub.edtech.co_student_data_transparency

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.co_student_data_transparency": true}, "public": {"data_inventory_published": true}, "security": {"program_defined": true}, "vendor": {"contract_compliant": true}}
}

test_denies_when_public_data_inventory_published_false if {
	count(deny) > 0 with input as {"controls": {"edtech.co_student_data_transparency": true}, "public": {"data_inventory_published": false}, "security": {"program_defined": true}, "vendor": {"contract_compliant": true}}
}

test_denies_when_security_program_defined_false if {
	count(deny) > 0 with input as {"controls": {"edtech.co_student_data_transparency": true}, "public": {"data_inventory_published": true}, "security": {"program_defined": false}, "vendor": {"contract_compliant": true}}
}

test_denies_when_vendor_contract_compliant_false if {
	count(deny) > 0 with input as {"controls": {"edtech.co_student_data_transparency": true}, "public": {"data_inventory_published": true}, "security": {"program_defined": true}, "vendor": {"contract_compliant": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.co_student_data_transparency": false}, "public": {"data_inventory_published": true}, "security": {"program_defined": true}, "vendor": {"contract_compliant": true}}
}

# Edge case: All conditions false
test_denies_when_all_false if {
	count(deny) > 0 with input as {"controls": {"edtech.co_student_data_transparency": true}, "public": {"data_inventory_published": false}, "security": {"program_defined": false}, "vendor": {"contract_compliant": false}}
}

# Auto-generated granular test for controls["edtech.co_student_data_transparency"]
test_denies_when_controls_edtech_co_student_data_transparency_failing if {
	some _ in deny with input as {"controls": {}, "public": {"data_inventory_published": true}, "security": {"program_defined": true}, "vendor": {"contract_compliant": true}, "controls[\"edtech": {"co_student_data_transparency\"]": false}}
}
