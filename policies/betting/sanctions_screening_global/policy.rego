package rulehub.betting.sanctions_screening_global

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.sanctions.hit
	input.account.blocked == false
	msg := "gambling.sanctions_screening_global: Screen customers against sanctions lists and block matches"
}

deny contains msg if {
	input.controls["betting.sanctions_screening_global"] == false
	msg := "betting.sanctions_screening_global: Generic control failed"
}
