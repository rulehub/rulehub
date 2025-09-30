package rulehub.medtech.hipaa_security_admin_safeguards

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.hipaa.security.risk_analysis_done == false
	msg := "medtech.hipaa_security_admin_safeguards: Risk analysis not performed"
}

deny contains msg if {
	input.hipaa.security.training_program == false
	msg := "medtech.hipaa_security_admin_safeguards: Workforce security/privacy training program missing"
}

deny contains msg if {
	input.hipaa.security.sanctions_policy == false
	msg := "medtech.hipaa_security_admin_safeguards: Sanctions policy for violations not defined"
}

deny contains msg if {
	input.controls["medtech.hipaa_security_admin_safeguards"] == false
	msg := "medtech.hipaa_security_admin_safeguards: Generic control failed"
}
