package rulehub.betting.license_check_spillemyndigheden_dk

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_spillemyndigheden_dk: Operator licensed by Spillemyndigheden"
}

deny contains msg if {
	input.controls["betting.license_check_spillemyndigheden_dk"] == false
	msg := "gambling.license_check_spillemyndigheden_dk: Generic control failed"
}
