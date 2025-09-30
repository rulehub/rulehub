package rulehub.edtech.au_app_11_security_edtech

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.au_app_11_security_edtech": true}, "security": {"encryption_at_rest": true}}
}

test_denies_when_security_encryption_at_rest_false if {
	count(deny) > 0 with input as {"controls": {"edtech.au_app_11_security_edtech": true}, "security": {"encryption_at_rest": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.au_app_11_security_edtech": false}, "security": {"encryption_at_rest": true}}
}

test_denies_when_both_encryption_and_control_fail if {
	count(deny) > 0 with input as {"controls": {"edtech.au_app_11_security_edtech": false}, "security": {"encryption_at_rest": false}}
}
