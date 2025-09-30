package rulehub.fintech.mtls_required

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.mtls_required"] == false
	msg := "fintech.mtls_required: Generic fintech control failed"
}
