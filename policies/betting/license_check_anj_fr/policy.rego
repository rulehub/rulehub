package rulehub.betting.license_check_anj_fr

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_anj_fr: Operator licensed by ANJ"
}

deny contains msg if {
	input.controls["betting.license_check_anj_fr"] == false
	msg := "gambling.license_check_anj_fr: Generic control failed"
}
