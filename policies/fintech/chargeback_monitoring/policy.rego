package rulehub.fintech.chargeback_monitoring

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.chargeback_monitoring"] == false
	msg := "fintech.chargeback_monitoring: Generic fintech control failed"
}
