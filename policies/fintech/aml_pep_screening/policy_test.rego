package rulehub.fintech.aml_pep_screening

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_pep_screening": true}, "aml": {"pep_checked": true}}
}

test_denies_when_aml_pep_checked_false if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_pep_screening": true}, "aml": {"pep_checked": false}}
}
