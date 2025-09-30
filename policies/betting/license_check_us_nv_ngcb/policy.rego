package rulehub.betting.license_check_us_nv_ngcb

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_us_nv_ngcb: Operator licensed by Nevada NGCB"
}

deny contains msg if {
	input.controls["betting.license_check_us_nv_ngcb"] == false
	msg := "gambling.license_check_us_nv_ngcb: Generic control failed"
}
