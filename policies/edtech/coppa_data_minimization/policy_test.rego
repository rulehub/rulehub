package rulehub.edtech.coppa_data_minimization

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.coppa_data_minimization": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"edtech.coppa_data_minimization": false}}
}

# Evidence-based deny: collected fields greater than necessary for child users
test_denies_when_child_data_excessive if {
	count(deny) > 0 with input as {"controls": {"edtech.coppa_data_minimization": true}, "coppa": {"collected_fields": 15, "necessary_fields": 4}}
}

test_denies_when_excessive_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.coppa_data_minimization": false}, "data": {"collected_fields": 15, "necessary_fields": 4}}
}
