package rulehub.fintech.aml_account_freeze_on_hit

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.aml_account_freeze_on_hit"] == false
	msg := "fintech.aml_account_freeze_on_hit: Generic fintech control failed"
}
