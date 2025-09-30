package rulehub.legaltech.records_classification_scheme_applied

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.records_classification_scheme_applied": true}, "records": {"classification_applied": true}}
}

test_denies_when_records_classification_applied_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.records_classification_scheme_applied": true}, "records": {"classification_applied": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.records_classification_scheme_applied": false}, "records": {"classification_applied": true}}
}

test_denies_when_control_disabled_and_classification_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.records_classification_scheme_applied": false}, "records": {"classification_applied": false}}
}
