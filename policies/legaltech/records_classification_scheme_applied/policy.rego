package rulehub.legaltech.records_classification_scheme_applied

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.records.classification_applied == false
	msg := "legaltech.records_classification_scheme_applied: Apply records classification scheme"
}

deny contains msg if {
	input.controls["legaltech.records_classification_scheme_applied"] == false
	msg := "legaltech.records_classification_scheme_applied: Generic control failed"
}
