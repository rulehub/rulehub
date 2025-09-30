package rulehub.legaltech.uk_gdpr_minor_consent

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.user.age < 13
	input.parental_consent == false
	msg := "legaltech.uk_gdpr_minor_consent: Parental consent for under-13"
}

deny contains msg if {
	input.controls["legaltech.uk_gdpr_minor_consent"] == false
	msg := "legaltech.uk_gdpr_minor_consent: Generic control failed"
}
