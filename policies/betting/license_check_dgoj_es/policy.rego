package rulehub.betting.license_check_dgoj_es

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_dgoj_es: Operator licensed by DGOJ"
}

deny contains msg if {
	input.controls["betting.license_check_dgoj_es"] == false
	msg := "gambling.license_check_dgoj_es: Generic control failed"
}
