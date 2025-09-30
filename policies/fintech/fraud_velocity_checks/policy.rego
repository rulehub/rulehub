package rulehub.fintech.fraud_velocity_checks

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.transaction.count_24h > input.thresholds.txn_velocity_max
	msg := "fintech.fraud_velocity_checks: Transaction velocity exceeded"
}
