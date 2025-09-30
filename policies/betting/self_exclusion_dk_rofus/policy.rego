package rulehub.betting.self_exclusion_dk_rofus

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.in_rofus
	input.session.blocked == false
	msg := "gambling.self_exclusion_dk_rofus: Block players registered in ROFUS"
}

deny contains msg if {
	input.controls["betting.self_exclusion_dk_rofus"] == false
	msg := "betting.self_exclusion_dk_rofus: Generic control failed"
}
