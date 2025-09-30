package rulehub.fintech.aml_sanctions_screening

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.aml.sanctions_screened == false
	msg := "fintech.aml_sanctions_screening: Sanctions screening not performed"
}
