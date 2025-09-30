package rulehub.edtech.edtech_access_least_privilege

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.security.least_privilege_enforced == false
	msg := "edtech.edtech_access_least_privilege: Enforce least privilege to student records"
}

deny contains msg if {
	input.controls["edtech.edtech_access_least_privilege"] == false
	msg := "edtech.edtech_access_least_privilege: Generic control failed"
}
