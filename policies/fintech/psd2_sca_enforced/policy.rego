package rulehub.fintech.psd2_sca_enforced

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.psd2_sca_enforced"] == false
	input.transaction.sca_passed == false
	msg := "fintech.psd2_sca_enforced: SCA/3DS not satisfied"
}
