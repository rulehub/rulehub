package rulehub.legaltech.encryption_at_rest_enabled

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.encryption_at_rest_enabled": true}, "security": {"encryption_at_rest": true}}
}

test_denies_when_security_encryption_at_rest_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.encryption_at_rest_enabled": true}, "security": {"encryption_at_rest": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.encryption_at_rest_enabled": false}, "security": {"encryption_at_rest": true}}
}

test_denies_when_control_disabled_and_encryption_at_rest_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.encryption_at_rest_enabled": false}, "security": {"encryption_at_rest": false}}
}
