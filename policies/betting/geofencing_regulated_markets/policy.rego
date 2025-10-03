package rulehub.betting.geofencing_regulated_markets

import future.keywords.in

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.geo != ""
	allowed := input.allowed_markets
	input.player.geo in (allowed == false)
	msg := "gambling.geofencing_regulated_markets: Geo-block unlicensed markets; robust anti‑spoofing"
}

deny contains msg if {
	input.controls["betting.geofencing_regulated_markets"] == false
	msg := "gambling.geofencing_regulated_markets: Generic control failed"
}
