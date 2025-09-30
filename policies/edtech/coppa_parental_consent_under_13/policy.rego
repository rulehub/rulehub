package rulehub.edtech.coppa_parental_consent_under_13

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.child.age < 13
	input.coppa.verifiable_parental_consent == false
	msg := "edtech.coppa_parental_consent_under_13: Obtain verifiable parental consent before collecting personal info from children under 13"
}

deny contains msg if {
	input.controls["edtech.coppa_parental_consent_under_13"] == false
	msg := "edtech.coppa_parental_consent_under_13: Generic control failed"
}
