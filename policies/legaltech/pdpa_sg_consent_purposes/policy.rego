package rulehub.legaltech.pdpa_sg_consent_purposes

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.pdpa.sg_purposes_specified == false
	msg := "legaltech.pdpa_sg_consent_purposes: Consent for purposes; notification requirements"
}

deny contains msg if {
	input.controls["legaltech.pdpa_sg_consent_purposes"] == false
	msg := "legaltech.pdpa_sg_consent_purposes: Generic control failed"
}
