package rulehub.betting.license_check_au_nt

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_au_nt: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_au_nt"]
	c == false
	msg := "betting.license_check_au_nt: Generic control failed"
}
