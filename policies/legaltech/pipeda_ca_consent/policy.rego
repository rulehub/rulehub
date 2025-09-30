package rulehub.legaltech.pipeda_ca_consent

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.pipeda.consent_obtained == false
	msg := "legaltech.pipeda_ca_consent: Obtain meaningful consent"
}

deny contains msg if {
	input.controls["legaltech.pipeda_ca_consent"] == false
	msg := "legaltech.pipeda_ca_consent: Generic control failed"
}
