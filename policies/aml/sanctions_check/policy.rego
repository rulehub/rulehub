package rulehub.aml.sanctions_check

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["aml.sanctions_check"] == false
	msg := "aml.sanctions_check: sanctions screening not enforced"
}
