package rulehub.igaming.license_check_adm_it

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_adm_it: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_adm_it"]
	c == false
	msg := "betting.license_check_adm_it: Generic control failed"
}
