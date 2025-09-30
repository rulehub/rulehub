package rulehub.aml.minimum_age

test_allow_when_compliant if {
	allow with input as {"controls": {"aml.minimum_age": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"aml.minimum_age": false}}
}
