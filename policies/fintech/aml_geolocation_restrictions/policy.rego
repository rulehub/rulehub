package rulehub.fintech.aml_geolocation_restrictions

import future.keywords.in

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.transaction.geo in input.restrictions.blocked_geos
	msg := "fintech.aml_geolocation_restrictions: Transaction from restricted geography"
}
