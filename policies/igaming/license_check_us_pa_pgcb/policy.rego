package rulehub.igaming.license_check_us_pa_pgcb

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_us_pa_pgcb: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_us_pa_pgcb"]
	c == false
	msg := "betting.license_check_us_pa_pgcb: Generic control failed"
}
