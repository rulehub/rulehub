package rulehub.fintech.fraud_velocity_checks

# curated: add transaction.count_24h and thresholds
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.fraud_velocity_checks": true}, "transaction": {"count_24h": 50}, "thresholds": {"txn_velocity_max": 100}}
}

test_denies_when_transaction_velocity_exceeded if {
	count(deny) > 0 with input as {"controls": {"fintech.fraud_velocity_checks": true}, "transaction": {"count_24h": 150}, "thresholds": {"txn_velocity_max": 100}}
}
