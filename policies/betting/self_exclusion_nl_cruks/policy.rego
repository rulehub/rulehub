package rulehub.betting.self_exclusion_nl_cruks

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.in_cruks
	input.session.blocked == false
	msg := "gambling.self_exclusion_nl_cruks: Block players listed in CRUKS"
}

deny contains msg if {
	input.controls["betting.self_exclusion_nl_cruks"] == false
	msg := "betting.self_exclusion_nl_cruks: Generic control failed"
}
