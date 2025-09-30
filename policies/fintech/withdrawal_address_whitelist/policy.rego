package rulehub.fintech.withdrawal_address_whitelist

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.withdrawal_address_whitelist"] == false
	msg := "fintech.withdrawal_address_whitelist: Generic fintech control failed"
}
