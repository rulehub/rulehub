package rulehub.edtech.br_lgpd_children_consent_best_interest

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.child.age < 13
	input.parental_consent == false
	msg := "edtech.br_lgpd_children_consent_best_interest: Parental consent and best interest for processing children’s data"
}

deny contains msg if {
	input.controls["edtech.br_lgpd_children_consent_best_interest"] == false
	msg := "edtech.br_lgpd_children_consent_best_interest: Generic control failed"
}
