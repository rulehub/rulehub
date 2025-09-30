package rulehub.medtech.log_retention_for_clinical_events

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.logs.retention_days < input.policy.logs.min_retention_days
	msg := "medtech.log_retention_for_clinical_events: Retain audit logs for clinical events per policy/regs"
}

deny contains msg if {
	input.controls["medtech.log_retention_for_clinical_events"] == false
	msg := "medtech.log_retention_for_clinical_events: Generic control failed"
}
