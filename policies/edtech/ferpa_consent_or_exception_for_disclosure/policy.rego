package rulehub.edtech.ferpa_consent_or_exception_for_disclosure

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.disclosure.requested
	input.disclosure.has_consent == false
	input.disclosure.exception_applies == false
	msg := "edtech.ferpa_consent_or_exception_for_disclosure: Do not disclose personally identifiable information without consent or valid exception"
}

deny contains msg if {
	input.controls["edtech.ferpa_consent_or_exception_for_disclosure"] == false
	msg := "edtech.ferpa_consent_or_exception_for_disclosure: Generic control failed"
}
