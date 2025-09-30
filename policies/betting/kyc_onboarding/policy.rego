package rulehub.betting.kyc_onboarding

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.player.kyc_completed == false
	msg := "betting.kyc_onboarding: KYC not completed"
}

deny contains msg if {
	c := input.controls["betting.kyc_onboarding"]
	c == false
	msg := "betting.kyc_onboarding: Generic control failed"
}
