package rulehub.igaming.license_check_us_nv_ngcb

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_us_nv_ngcb: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_us_nv_ngcb"]
	c == false
	msg := "betting.license_check_us_nv_ngcb: Generic control failed"
}
