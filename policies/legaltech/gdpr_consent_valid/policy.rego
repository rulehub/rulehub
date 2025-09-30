package rulehub.legaltech.gdpr_consent_valid

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.consent.informed == false
	msg := "legaltech.gdpr_consent_valid: Consent is informed, freely given, unambiguous, recorded"
}

deny contains msg if {
	input.consent.freely_given == false
	msg := "legaltech.gdpr_consent_valid: Consent is informed, freely given, unambiguous, recorded"
}

deny contains msg if {
	input.consent.unambiguous == false
	msg := "legaltech.gdpr_consent_valid: Consent is informed, freely given, unambiguous, recorded"
}

deny contains msg if {
	input.consent.recorded == false
	msg := "legaltech.gdpr_consent_valid: Consent is informed, freely given, unambiguous, recorded"
}

deny contains msg if {
	input.controls["legaltech.gdpr_consent_valid"] == false
	msg := "legaltech.gdpr_consent_valid: Generic control failed"
}
