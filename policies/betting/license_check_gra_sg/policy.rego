package rulehub.betting.license_check_gra_sg

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_gra_sg: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_gra_sg"]
	c == false
	msg := "betting.license_check_gra_sg: Generic control failed"
}
