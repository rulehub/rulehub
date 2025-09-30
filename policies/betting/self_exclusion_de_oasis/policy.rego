package rulehub.betting.self_exclusion_de_oasis

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.in_oasis
	input.session.blocked == false
	msg := "gambling.self_exclusion_de_oasis: Block players in OASIS nationwide exclusion system"
}

deny contains msg if {
	input.controls["betting.self_exclusion_de_oasis"] == false
	msg := "betting.self_exclusion_de_oasis: Generic control failed"
}
