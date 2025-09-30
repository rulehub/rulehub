package rulehub.betting.license_check_ggl_de

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_ggl_de: Operator licensed by GGL under GlüStV 2021"
}

deny contains msg if {
	input.controls["betting.license_check_ggl_de"] == false
	msg := "gambling.license_check_ggl_de: Generic control failed"
}
