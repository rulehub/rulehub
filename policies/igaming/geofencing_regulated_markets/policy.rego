package rulehub.igaming.geofencing_regulated_markets

import future.keywords.in

default allow := false

allow if count(deny) == 0

deny contains msg if {
	# player geo not in the list of allowed markets
	input.player.geo != ""
	allowed := input.allowed_markets
	input.player.geo in (allowed == false)
	msg := "betting.geofencing_regulated_markets: Access from unregulated/unlicensed market"
}

deny contains msg if {
	c := input.controls["betting.geofencing_regulated_markets"]
	c == false
	msg := "betting.geofencing_regulated_markets: Generic control failed"
}
