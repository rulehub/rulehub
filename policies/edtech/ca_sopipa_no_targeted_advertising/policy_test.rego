package rulehub.edtech.ca_sopipa_no_targeted_advertising

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.ca_sopipa_no_targeted_advertising": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ca_sopipa_no_targeted_advertising": false}}
}

test_denies_when_targeted_ads_based_on_student_data if {
	count(deny) > 0 with input as {
		"ads": {"targeted_using_student_data": true},
		"controls": {"edtech.ca_sopipa_no_targeted_advertising": true},
	}
}

test_denies_when_targeted_ads_and_control_disabled if {
	count(deny) > 0 with input as {
		"ads": {"targeted_using_student_data": true},
		"controls": {"edtech.ca_sopipa_no_targeted_advertising": false},
	}
}
