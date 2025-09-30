package rulehub.edtech.edtech_audit_logs_student_record_access

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.logs.audit_trail_available == false
	msg := "edtech.edtech_audit_logs_student_record_access: Maintain audit trail when accessing student records"
}

deny contains msg if {
	input.controls["edtech.edtech_audit_logs_student_record_access"] == false
	msg := "edtech.edtech_audit_logs_student_record_access: Generic control failed"
}
