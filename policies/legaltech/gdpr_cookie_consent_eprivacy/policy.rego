package rulehub.legaltech.gdpr_cookie_consent_eprivacy

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.cookies.non_essential_set_before_consent == true
	msg := "legaltech.gdpr_cookie_consent_eprivacy: Non-essential cookies after consent"
}

deny contains msg if {
	input.controls["legaltech.gdpr_cookie_consent_eprivacy"] == false
	msg := "legaltech.gdpr_cookie_consent_eprivacy: Generic control failed"
}
