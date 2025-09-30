package rulehub.fintech.hot_wallet_limits

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.hot_wallet_limits"] == false
	msg := "fintech.hot_wallet_limits: Generic fintech control failed"
}
