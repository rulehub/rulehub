package rulehub.edtech.ppra_parental_consent_sensitive_surveys

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.survey.contains_sensitive_topics
	input.survey.parental_consent_obtained == false
	msg := "edtech.ppra_parental_consent_sensitive_surveys: Parental consent required before students participate in certain surveys"
}

deny contains msg if {
	input.controls["edtech.ppra_parental_consent_sensitive_surveys"] == false
	msg := "edtech.ppra_parental_consent_sensitive_surveys: Generic control failed"
}
