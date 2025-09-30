package rulehub.edtech.edtech_retention_after_course_completion

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.data.retention_days > input.policy.retention.max_days
	msg := "edtech.edtech_retention_after_course_completion: Retention ≤ policy; timely deletion after course end"
}

deny contains msg if {
	input.controls["edtech.edtech_retention_after_course_completion"] == false
	msg := "edtech.edtech_retention_after_course_completion: Generic control failed"
}
