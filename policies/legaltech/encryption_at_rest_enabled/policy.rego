package rulehub.legaltech.encryption_at_rest_enabled

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.security.encryption_at_rest == false
	msg := "legaltech.encryption_at_rest_enabled: Encrypt legal data at rest"
}

deny contains msg if {
	input.controls["legaltech.encryption_at_rest_enabled"] == false
	msg := "legaltech.encryption_at_rest_enabled: Generic control failed"
}
