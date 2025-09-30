package rulehub.betting.license_check_us_co_division

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_us_co_division: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_us_co_division"]
	c == false
	msg := "betting.license_check_us_co_division: Generic control failed"
}
