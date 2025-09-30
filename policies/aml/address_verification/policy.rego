package rulehub.aml.address_verification

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["aml.address_verification"] == false
	msg := "aml.address_verification: customer address not verified"
}
