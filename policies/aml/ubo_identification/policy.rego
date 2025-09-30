package rulehub.aml.ubo_identification

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["aml.ubo_identification"] == false
	msg := "aml.ubo_identification: beneficial ownership not identified"
}
