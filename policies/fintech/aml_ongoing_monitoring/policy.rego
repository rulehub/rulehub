package rulehub.fintech.aml_ongoing_monitoring

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.aml.ongoing_monitoring_enabled == false
	msg := "fintech.aml_ongoing_monitoring: Ongoing monitoring disabled"
}
