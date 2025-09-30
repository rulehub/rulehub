package rulehub.medtech.au_myr_health_privacy

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.mhr.access_controls == false
	msg := "medtech.au_myr_health_privacy: Missing access controls"
}

deny contains msg if {
	input.mhr.security_measures == false
	msg := "medtech.au_myr_health_privacy: Missing security measures"
}

deny contains msg if {
	input.controls["medtech.au_myr_health_privacy"] == false
	msg := "medtech.au_myr_health_privacy: Generic control failed"
}
