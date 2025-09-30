package rulehub.medtech.hipaa_access_audit_logging

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.audit.ephi_access_logged == false
	msg := "medtech.hipaa_access_audit_logging: Enable audit controls to record and examine activity in systems containing ePHI"
}

deny contains msg if {
	input.controls["medtech.hipaa_access_audit_logging"] == false
	msg := "medtech.hipaa_access_audit_logging: Generic control failed"
}
