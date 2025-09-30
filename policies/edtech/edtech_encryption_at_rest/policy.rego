package rulehub.edtech.edtech_encryption_at_rest

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.security.encryption_at_rest == false
	msg := "edtech.edtech_encryption_at_rest: Encrypt student data at rest"
}

deny contains msg if {
	input.controls["edtech.edtech_encryption_at_rest"] == false
	msg := "edtech.edtech_encryption_at_rest: Generic control failed"
}
