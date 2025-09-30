package rulehub.edtech.eu_eprivacy_cookie_consent_edtech

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.cookies.non_essential_set_before_consent == true
	msg := "edtech.eu_eprivacy_cookie_consent_edtech: No non-essential cookies before consent"
}

deny contains msg if {
	input.controls["edtech.eu_eprivacy_cookie_consent_edtech"] == false
	msg := "edtech.eu_eprivacy_cookie_consent_edtech: Generic control failed"
}
