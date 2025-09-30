package rulehub.betting.self_exclusion_uk_gamstop

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.self_excluded == true
	input.session.blocked == false
	msg := "gambling.self_exclusion_uk_gamstop: Block self-excluded customers via GAMSTOP integration"
}

deny contains msg if {
	input.controls["betting.self_exclusion_uk_gamstop"] == false
	msg := "betting.self_exclusion_uk_gamstop: Generic control failed"
}
