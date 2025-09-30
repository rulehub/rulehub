package rulehub.fintech.ob_audit_logging

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.api.mtls_enabled == false
	msg := "fintech.ob_audit_logging: mTLS must be enabled"
}

deny contains msg if {
	input.api.oauth2_pkce == false
	msg := "fintech.ob_audit_logging: OAuth2 PKCE must be required"
}
