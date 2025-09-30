package rulehub.aml.pep_screening_required

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["aml.pep_screening_required"] == false
	msg := "aml.pep_screening_required: PEP screening not performed"
}
