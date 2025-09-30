package rulehub.fintech.xs2a_api_security

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.api.mtls_enabled == false
	msg := "fintech.xs2a_api_security: mTLS must be enabled"
}

deny contains msg if {
	input.api.oauth2_pkce == false
	msg := "fintech.xs2a_api_security: OAuth2 PKCE must be required"
}
