package rulehub.fintech.pan_masking_in_logs

# curated: include logs.line evidence
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pan_masking_in_logs": true}, "logs": {"line": "txn 1234 **** **** 1234"}}
}

test_denies_when_pan_exposed_in_logs if {
	count(deny) > 0 with input as {"controls": {"fintech.pan_masking_in_logs": true}, "logs": {"line": "4111111111111111"}}
}
