package rulehub.igaming.license_check_ukgc

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.operator.licensed == false
	msg := "betting.license_check_ukgc: Operator not licensed"
}

deny contains msg if {
	c := input.controls["betting.license_check_ukgc"]
	c == false
	msg := "betting.license_check_ukgc: Generic control failed"
}
