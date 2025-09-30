package rulehub.legaltech.gdpr_lawful_basis_required

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.gdpr.lawful_basis_documented == false
	msg := "legaltech.gdpr_lawful_basis_required: Lawful basis documented for each processing activity"
}

deny contains msg if {
	input.controls["legaltech.gdpr_lawful_basis_required"] == false
	msg := "legaltech.gdpr_lawful_basis_required: Generic control failed"
}
