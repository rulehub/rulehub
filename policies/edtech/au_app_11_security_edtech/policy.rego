package rulehub.edtech.au_app_11_security_edtech

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.security.encryption_at_rest == false
	msg := "edtech.au_app_11_security_edtech: Take reasonable steps to protect information (APP 11)"
}

deny contains msg if {
	input.controls["edtech.au_app_11_security_edtech"] == false
	msg := "edtech.au_app_11_security_edtech: Generic control failed"
}
