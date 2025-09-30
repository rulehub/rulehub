package rulehub.betting.market_restrictions_youth

import future.keywords.in

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.market.type == "youth_league"
	msg := "betting.market_restrictions_youth: Restricted betting market (youth league)"
}

deny contains msg if {
	input.market.type == "underage_event"
	msg := "betting.market_restrictions_youth: Restricted betting market (underage event)"
}

deny contains msg if {
	c := input.controls["betting.market_restrictions_youth"]
	c == false
	msg := "betting.market_restrictions_youth: Generic control failed"
}
