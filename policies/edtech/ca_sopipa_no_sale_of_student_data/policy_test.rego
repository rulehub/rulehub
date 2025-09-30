package rulehub.edtech.ca_sopipa_no_sale_of_student_data

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.ca_sopipa_no_sale_of_student_data": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ca_sopipa_no_sale_of_student_data": false}}
}

test_denies_when_student_data_sold if {
	count(deny) > 0 with input as {
		"data": {"sold_student_info": true},
		"controls": {"edtech.ca_sopipa_no_sale_of_student_data": true},
	}
}

test_denies_when_student_data_sold_and_control_disabled if {
	count(deny) > 0 with input as {
		"data": {"sold_student_info": true},
		"controls": {"edtech.ca_sopipa_no_sale_of_student_data": false},
	}
}
