package rulehub.legaltech.gdpr_data_minimization

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.data.collected_fields > input.data.necessary_fields
	msg := "legaltech.gdpr_data_minimization: Collect only necessary personal data"
}

deny contains msg if {
	input.controls["legaltech.gdpr_data_minimization"] == false
	msg := "legaltech.gdpr_data_minimization: Generic control failed"
}
