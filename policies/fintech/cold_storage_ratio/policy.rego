package rulehub.fintech.cold_storage_ratio

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.cold_storage_ratio"] == false
	msg := "fintech.cold_storage_ratio: Generic fintech control failed"
}
