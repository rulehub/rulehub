package rulehub.betting.license_check_adm_it

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_adm_it: Operator licensed by ADM"
}

deny contains msg if {
	input.controls["betting.license_check_adm_it"] == false
	msg := "gambling.license_check_adm_it: Generic control failed"
}
