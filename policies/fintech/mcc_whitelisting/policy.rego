package rulehub.fintech.mcc_whitelisting

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.mcc_whitelisting"] == false
	msg := "fintech.mcc_whitelisting: Generic fintech control failed"
}
