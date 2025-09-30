package rulehub.fintech.aml_sanctions_screening

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_sanctions_screening": true}, "aml": {"sanctions_screened": true}}
}

test_denies_when_aml_sanctions_screened_false if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_sanctions_screening": true}, "aml": {"sanctions_screened": false}}
}
