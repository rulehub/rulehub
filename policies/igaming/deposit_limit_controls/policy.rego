package rulehub.igaming.deposit_limit_controls

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.player.deposits.month_total > input.limits.monthly_max
	msg := sprintf("betting.deposit_limit_controls: Deposit limit exceeded (%.0f > %.0f)", [input.player.deposits.month_total, input.limits.monthly_max])
}

deny contains msg if {
	c := input.controls["igaming.deposit_limit_controls"]
	c == false
	msg := "igaming.deposit_limit_controls: Generic control failed"
}
