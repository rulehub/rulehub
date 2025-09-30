package rulehub.edtech.eu_gdpr_minors_consent_education

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.child.age < input.policy.eu.min_consent_age
	input.parental_consent == false
	msg := "edtech.eu_gdpr_minors_consent_education: Parental consent required for information society services to children (member-state age 13–16)"
}

deny contains msg if {
	input.controls["edtech.eu_gdpr_minors_consent_education"] == false
	msg := "edtech.eu_gdpr_minors_consent_education: Generic control failed"
}
