package rulehub.betting.safer_gambling_interactions

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.safer_gambling.proactive_interactions_enabled == false
	msg := "gambling.safer_gambling_interactions: Identify at-risk behavior and interact promptly"
}

deny contains msg if {
	input.controls["betting.safer_gambling_interactions"] == false
	msg := "betting.safer_gambling_interactions: Generic control failed"
}
