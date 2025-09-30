package rulehub.betting.license_check_mga

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_mga: Operator holds MGA license"
}

deny contains msg if {
	input.controls["betting.license_check_mga"] == false
	msg := "gambling.license_check_mga: Generic control failed"
}
