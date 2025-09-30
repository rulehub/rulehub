package rulehub.edtech.ct_student_data_privacy

# curated: include breach.occurred trigger for breach path
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.ct_student_data_privacy": true}, "breach": {"occurred": true, "notified": true}, "vendor": {"contract_compliant": true}}
}

test_denies_when_breach_notified_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ct_student_data_privacy": true}, "breach": {"occurred": true, "notified": false}, "vendor": {"contract_compliant": true}}
}

test_denies_when_vendor_contract_compliant_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ct_student_data_privacy": true}, "breach": {"occurred": false, "notified": true}, "vendor": {"contract_compliant": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ct_student_data_privacy": false}, "breach": {"occurred": false, "notified": true}, "vendor": {"contract_compliant": true}}
}

# Edge case: Breach occurred but not notified and vendor contract not compliant
test_denies_when_breach_not_notified_and_vendor_not_compliant if {
	count(deny) > 0 with input as {"controls": {"edtech.ct_student_data_privacy": true}, "breach": {"occurred": true, "notified": false}, "vendor": {"contract_compliant": false}}
}
