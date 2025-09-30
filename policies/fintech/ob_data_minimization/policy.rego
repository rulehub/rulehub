package rulehub.fintech.ob_data_minimization

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.api.mtls_enabled == false
	msg := "fintech.ob_data_minimization: mTLS must be enabled"
}

deny contains msg if {
	input.api.oauth2_pkce == false
	msg := "fintech.ob_data_minimization: OAuth2 PKCE must be required"
}
