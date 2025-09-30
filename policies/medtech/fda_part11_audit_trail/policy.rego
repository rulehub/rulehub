package rulehub.medtech.fda_part11_audit_trail

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

## Deny only when audit trail explicitly disabled
deny contains msg if {
	input.part11.audit_trail_enabled == false
	msg := "medtech.fda_part11_audit_trail: Secure, computer-generated time-stamped audit trail for record changes"
}

deny contains msg if {
	input.controls["medtech.fda_part11_audit_trail"] == false
	msg := "medtech.fda_part11_audit_trail: Generic control failed"
}
