package rulehub.fintech.three_ds_required

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.transaction.sca_passed == false
	msg := "fintech.three_ds_required: SCA/3DS not satisfied"
}
