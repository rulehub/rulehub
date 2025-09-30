package rulehub.fintech.device_fingerprinting

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.device_fingerprinting"] == false
	msg := "fintech.device_fingerprinting: Generic fintech control failed"
}
