package rulehub.fintech.aml_transaction_velocity_limits

# curated: include transaction velocity evidence
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_transaction_velocity_limits": true}, "transaction": {"count_24h": 80}, "thresholds": {"txn_velocity_max": 100}}
}

test_denies_when_velocity_exceeded if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_transaction_velocity_limits": true}, "transaction": {"count_24h": 150}, "thresholds": {"txn_velocity_max": 100}}
}
