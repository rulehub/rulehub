package rulehub.aml.minimum_age

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["aml.minimum_age"] == false
	msg := "aml.minimum_age: minimum age verification not enforced"
}
