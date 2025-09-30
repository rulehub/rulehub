package rulehub.fintech.aml_duplicate_account_detection

# curated: add customer.duplicate_detected evidence
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_duplicate_account_detection": true}, "customer": {"duplicate_detected": false}}
}

test_denies_when_customer_duplicate_detected_true if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_duplicate_account_detection": true}, "customer": {"duplicate_detected": true}}
}
