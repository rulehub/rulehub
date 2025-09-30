package rulehub.edtech.in_dpdpa_children_verifiable_consent

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.child.age < 18
	input.parental_consent == false
	msg := "edtech.in_dpdpa_children_verifiable_consent: Obtain verifiable parental consent for processing children’s data (child defined by law)"
}

deny contains msg if {
	input.controls["edtech.in_dpdpa_children_verifiable_consent"] == false
	msg := "edtech.in_dpdpa_children_verifiable_consent: Generic control failed"
}
