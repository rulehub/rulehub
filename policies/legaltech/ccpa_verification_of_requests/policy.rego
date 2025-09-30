package rulehub.legaltech.ccpa_verification_of_requests

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.ccpa.request_verified == false
	msg := "legaltech.ccpa_verification_of_requests: Verify identity for consumer requests"
}

deny contains msg if {
	input.controls["legaltech.ccpa_verification_of_requests"] == false
	msg := "legaltech.ccpa_verification_of_requests: Generic control failed"
}
