package rulehub.fintech.psd2_sca_exemptions_controls

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.psd2_sca_exemptions_controls"] == false
	input.transaction.sca_passed == false
	msg := "fintech.psd2_sca_exemptions_controls: SCA/3DS not satisfied"
}
