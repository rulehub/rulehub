package rulehub.igaming.license_check_dgoj_es

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_dgoj_es: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_dgoj_es"]
	c == false
	msg := "betting.license_check_dgoj_es: Generic control failed"
}
