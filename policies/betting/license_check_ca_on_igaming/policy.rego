package rulehub.betting.license_check_ca_on_igaming

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_ca_on_igaming: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_ca_on_igaming"]
	c == false
	msg := "betting.license_check_ca_on_igaming: Generic control failed"
}
