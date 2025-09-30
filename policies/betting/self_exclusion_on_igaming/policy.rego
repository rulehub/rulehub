package rulehub.betting.self_exclusion_on_igaming

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.on_self_excluded
	input.session.blocked == false
	msg := "gambling.self_exclusion_on_igaming: Block self-excluded players per Ontario iGaming program"
}

deny contains msg if {
	input.controls["betting.self_exclusion_on_igaming"] == false
	msg := "betting.self_exclusion_on_igaming: Generic control failed"
}
