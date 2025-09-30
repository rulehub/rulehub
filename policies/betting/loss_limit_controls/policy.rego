package rulehub.betting.loss_limit_controls

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.limits.loss_limit_enabled == false
	msg := "gambling.loss_limit_controls: Allow players to set enforceable loss limits"
}

deny contains msg if {
	input.controls["betting.loss_limit_controls"] == false
	msg := "gambling.loss_limit_controls: Generic control failed"
}
