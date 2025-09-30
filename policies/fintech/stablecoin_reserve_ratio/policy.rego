package rulehub.fintech.stablecoin_reserve_ratio

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.stablecoin_reserve_ratio"] == false
	msg := "fintech.stablecoin_reserve_ratio: Generic fintech control failed"
}
