package rulehub.fintech.aml_unusual_activity_alerting

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.aml_unusual_activity_alerting"] == false
	msg := "fintech.aml_unusual_activity_alerting: Generic fintech control failed"
}
