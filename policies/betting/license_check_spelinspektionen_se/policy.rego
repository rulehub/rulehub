package rulehub.betting.license_check_spelinspektionen_se

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_spelinspektionen_se: Operator licensed by Spelinspektionen"
}

deny contains msg if {
	input.controls["betting.license_check_spelinspektionen_se"] == false
	msg := "gambling.license_check_spelinspektionen_se: Generic control failed"
}
