package rulehub.fintech.ip_geolocation_consistency

import future.keywords.in

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.transaction.geo in input.restrictions.blocked_geos
	msg := "fintech.ip_geolocation_consistency: Transaction from restricted geography"
}
