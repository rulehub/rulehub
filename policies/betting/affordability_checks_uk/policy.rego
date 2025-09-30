package rulehub.betting.affordability_checks_uk

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.player.net_deposit_30d > input.affordability.max_30d
	msg := "betting.affordability_checks_uk: Affordability threshold exceeded"
}

deny contains msg if {
	c := input.controls["betting.affordability_checks_uk"]
	c == false
	msg := "betting.affordability_checks_uk: Generic control failed"
}
