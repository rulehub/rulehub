package rulehub.medtech.hipaa_minimum_necessary

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.hipaa_minimum_necessary": true}, "hipaa": {"privacy": {"minimum_necessary_enforced": true}}}
}

test_denies_when_hipaa_privacy_minimum_necessary_enforced_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_minimum_necessary": true}, "hipaa": {"privacy": {"minimum_necessary_enforced": false}}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_minimum_necessary": false}, "hipaa": {"privacy": {"minimum_necessary_enforced": true}}}
}

test_denies_when_control_disabled_and_minimum_necessary_not_enforced if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_minimum_necessary": false}, "hipaa": {"privacy": {"minimum_necessary_enforced": false}}}
}

# Additional Phase1 assertion: missing minimum necessary field should deny
test_additional_denies_when_minimum_necessary_field_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_minimum_necessary": false}, "hipaa": {"privacy": {"minimum_necessary_enforced": true}}}
}
