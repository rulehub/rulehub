package rulehub.fintech.transaction_limits_per_risk

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.transaction_limits_per_risk"] == false
	msg := "fintech.transaction_limits_per_risk: Generic fintech control failed"
}
