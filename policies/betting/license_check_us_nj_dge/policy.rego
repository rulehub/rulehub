package rulehub.betting.license_check_us_nj_dge

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_us_nj_dge: Operator licensed by NJ DGE"
}

deny contains msg if {
	input.controls["betting.license_check_us_nj_dge"] == false
	msg := "gambling.license_check_us_nj_dge: Generic control failed"
}
