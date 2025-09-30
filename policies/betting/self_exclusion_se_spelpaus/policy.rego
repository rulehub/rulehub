package rulehub.betting.self_exclusion_se_spelpaus

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.in_spelpaus
	input.session.blocked == false
	msg := "gambling.self_exclusion_se_spelpaus: Block players registered in Spelpaus"
}

deny contains msg if {
	input.controls["betting.self_exclusion_se_spelpaus"] == false
	msg := "betting.self_exclusion_se_spelpaus: Generic control failed"
}
