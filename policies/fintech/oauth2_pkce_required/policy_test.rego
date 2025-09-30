package rulehub.fintech.oauth2_pkce_required

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.oauth2_pkce_required": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.oauth2_pkce_required": false}}
}
