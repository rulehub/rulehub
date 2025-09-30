package rulehub.betting.license_check_us_pa_pgcb

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_us_pa_pgcb: Operator licensed by PA PGCB"
}

deny contains msg if {
	input.controls["betting.license_check_us_pa_pgcb"] == false
	msg := "gambling.license_check_us_pa_pgcb: Generic control failed"
}
