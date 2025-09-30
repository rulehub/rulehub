package rulehub.edtech.kr_pipa_guardian_consent_under_14

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.child.age < 14
	input.parental_consent == false
	msg := "edtech.kr_pipa_guardian_consent_under_14: Guardian consent required for children under 14"
}

deny contains msg if {
	input.controls["edtech.kr_pipa_guardian_consent_under_14"] == false
	msg := "edtech.kr_pipa_guardian_consent_under_14: Generic control failed"
}
