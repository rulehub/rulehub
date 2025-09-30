package rulehub.legaltech.popia_za_security_measures

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.popia.security_measures_applied == false
	msg := "legaltech.popia_za_security_measures: Appropriate security safeguards"
}

deny contains msg if {
	input.controls["legaltech.popia_za_security_measures"] == false
	msg := "legaltech.popia_za_security_measures: Generic control failed"
}
