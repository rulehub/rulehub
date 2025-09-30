package rulehub.betting.self_exclusion_es_rgiaj

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.in_rgiaj
	input.session.blocked == false
	msg := "gambling.self_exclusion_es_rgiaj: Block players in RGIAJ registry"
}

deny contains msg if {
	input.controls["betting.self_exclusion_es_rgiaj"] == false
	msg := "betting.self_exclusion_es_rgiaj: Generic control failed"
}
