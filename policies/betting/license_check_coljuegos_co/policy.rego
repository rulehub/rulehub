package rulehub.betting.license_check_coljuegos_co

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_coljuegos_co: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_coljuegos_co"]
	c == false
	msg := "betting.license_check_coljuegos_co: Generic control failed"
}
