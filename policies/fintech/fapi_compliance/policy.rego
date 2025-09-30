package rulehub.fintech.fapi_compliance

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.fapi_compliance"] == false
	msg := "fintech.fapi_compliance: Generic fintech control failed"
}
