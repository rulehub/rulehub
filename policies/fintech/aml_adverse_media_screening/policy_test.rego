package rulehub.fintech.aml_adverse_media_screening

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_adverse_media_screening": true}, "aml": {"adverse_media_screened": true}}
}

test_denies_when_aml_adverse_media_screened_false if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_adverse_media_screening": true}, "aml": {"adverse_media_screened": false}}
}
