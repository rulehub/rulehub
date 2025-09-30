package rulehub.fintech.aml_pep_screening

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.aml.pep_checked == false
	msg := "fintech.aml_pep_screening: PEP screening not performed"
}
