package rulehub.fintech.geofencing_restricted_markets

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.geofencing_restricted_markets"] == false
	msg := "fintech.geofencing_restricted_markets: Generic fintech control failed"
}
