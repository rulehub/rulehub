package rulehub.betting.deposit_limit_controls

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.limits.deposit_limit_enabled == false
	msg := "betting.deposit_limit_controls: Deposit limits must be enabled"
}

deny contains msg if {
	input.limits.limit_exceeded == true
	input.limits.limit_applied == false
	msg := "betting.deposit_limit_controls: Exceeded deposit limit not enforced"
}

deny contains msg if {
	input.controls["betting.deposit_limit_controls"] == false
	msg := "betting.deposit_limit_controls: Generic control failed"
}
