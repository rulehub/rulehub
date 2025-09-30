package rulehub.betting.license_check_agco_on

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.operator.licensed == false
	msg := "gambling.license_check_agco_on: Operator registered by AGCO and operating under iGaming Ontario"
}

deny contains msg if {
	input.controls["betting.license_check_agco_on"] == false
	msg := "gambling.license_check_agco_on: Generic control failed"
}
