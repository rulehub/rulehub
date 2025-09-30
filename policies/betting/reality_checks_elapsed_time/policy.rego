package rulehub.betting.reality_checks_elapsed_time

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.session.reality_checks_enabled == false
	msg := "gambling.reality_checks_elapsed_time: Display elapsed session time; provide periodic reality checks"
}

deny contains msg if {
	input.controls["betting.reality_checks_elapsed_time"] == false
	msg := "betting.reality_checks_elapsed_time: Generic control failed"
}
