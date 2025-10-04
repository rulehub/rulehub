package rulehub.igaming.geofencing_regulated_markets

import future.keywords.in

default allow := false

allow if {
	count(deny) == 0
}

deny contains msg if {
	# player geo not in the list of allowed markets
	input.player.geo != ""
	allowed := input.allowed_markets
	not input.player.geo in allowed
	msg := "igaming.geofencing_regulated_markets: Geo-block unlicensed markets; robust anti-spoofing"
}

deny contains msg if {
	c := input.controls["igaming.geofencing_regulated_markets"]
	c == false
	msg := "igaming.geofencing_regulated_markets: Generic control failed"
}
