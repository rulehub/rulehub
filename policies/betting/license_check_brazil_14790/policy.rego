package rulehub.betting.license_check_brazil_14790

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_brazil_14790: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_brazil_14790"]
	c == false
	msg := "betting.license_check_brazil_14790: Generic control failed"
}
