package rulehub.fintech.kyc_biometric_liveness

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.kyc.liveness_passed == false
	msg := "fintech.kyc_biometric_liveness: Biometric liveness failed/missing"
}
