package rulehub.betting.source_of_funds_checks

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.high_spend
	input.player.sof_collected == false
	msg := "gambling.source_of_funds_checks: Evidence of source of funds for high-spend players"
}

deny contains msg if {
	input.controls["betting.source_of_funds_checks"] == false
	msg := "betting.source_of_funds_checks: Generic control failed"
}
