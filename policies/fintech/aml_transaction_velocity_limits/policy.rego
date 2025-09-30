package rulehub.fintech.aml_transaction_velocity_limits

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.transaction.count_24h > input.thresholds.txn_velocity_max
	msg := "fintech.aml_transaction_velocity_limits: Transaction velocity exceeded"
}
