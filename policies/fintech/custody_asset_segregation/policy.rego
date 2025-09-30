package rulehub.fintech.custody_asset_segregation

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.custody_asset_segregation"] == false
	msg := "fintech.custody_asset_segregation: Generic fintech control failed"
}
