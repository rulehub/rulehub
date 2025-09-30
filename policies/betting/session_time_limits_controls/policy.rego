package rulehub.betting.session_time_limits_controls

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.limits.session_time_limit_enabled == false
	msg := "gambling.session_time_limits_controls: Allow players to set session time limits"
}

deny contains msg if {
	input.controls["betting.session_time_limits_controls"] == false
	msg := "betting.session_time_limits_controls: Generic control failed"
}
