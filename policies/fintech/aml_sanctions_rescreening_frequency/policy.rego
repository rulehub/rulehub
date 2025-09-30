package rulehub.fintech.aml_sanctions_rescreening_frequency

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.aml.sanctions_screened == false
	msg := "fintech.aml_sanctions_rescreening_frequency: Sanctions screening not performed"
}
