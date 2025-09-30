package rulehub.fintech.ob_audit_logging

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.ob_audit_logging": true}, "api": {"mtls_enabled": true, "oauth2_pkce": true}}
}

test_denies_when_api_mtls_enabled_false if {
	count(deny) > 0 with input as {"controls": {"fintech.ob_audit_logging": true}, "api": {"mtls_enabled": false, "oauth2_pkce": true}}
}

test_denies_when_api_oauth2_pkce_false if {
	count(deny) > 0 with input as {"controls": {"fintech.ob_audit_logging": true}, "api": {"mtls_enabled": true, "oauth2_pkce": false}}
}

test_denies_when_both_mtls_and_pkce_disabled if {
	count(deny) > 0 with input as {"controls": {"fintech.ob_audit_logging": true}, "api": {"mtls_enabled": false, "oauth2_pkce": false}}
}
