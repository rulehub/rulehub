package rulehub.fintech.ob_tpp_eidas_cert_validation

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.api.mtls_enabled == false
	msg := "fintech.ob_tpp_eidas_cert_validation: mTLS must be enabled"
}

deny contains msg if {
	input.api.oauth2_pkce == false
	msg := "fintech.ob_tpp_eidas_cert_validation: OAuth2 PKCE must be required"
}
