package rulehub.fintech.kyc_reverification_schedule

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.kyc_reverification_schedule"] == false
	msg := "fintech.kyc_reverification_schedule: Generic fintech control failed"
}
