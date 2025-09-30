package rulehub.betting.license_check_ksa_nl

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_ksa_nl: Operator licensed by KSA"
}

deny contains msg if {
	input.controls["betting.license_check_ksa_nl"] == false
	msg := "gambling.license_check_ksa_nl: Generic control failed"
}
