package rulehub.igaming.license_check_us_nj_dge

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_us_nj_dge: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_us_nj_dge"]
	c == false
	msg := "betting.license_check_us_nj_dge: Generic control failed"
}
