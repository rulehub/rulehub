package rulehub.medtech.iso_27001_isms_scope_and_controls

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.isms.scope_defined == false
	msg := "medtech.iso_27001_isms_scope_and_controls: ISMS scope not clearly defined"
}

deny contains msg if {
	input.isms.controls_implemented == false
	msg := "medtech.iso_27001_isms_scope_and_controls: Required Annex A controls not implemented"
}

deny contains msg if {
	input.controls["medtech.iso_27001_isms_scope_and_controls"] == false
	msg := "medtech.iso_27001_isms_scope_and_controls: Generic control failed"
}
