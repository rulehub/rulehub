package rulehub.legaltech.encryption_in_transit_enabled

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.encryption_in_transit_enabled": true}, "security": {"encryption_in_transit": true}}
}

test_denies_when_security_encryption_in_transit_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.encryption_in_transit_enabled": true}, "security": {"encryption_in_transit": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.encryption_in_transit_enabled": false}, "security": {"encryption_in_transit": true}}
}

test_denies_when_control_disabled_and_encryption_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.encryption_in_transit_enabled": false}, "security": {"encryption_in_transit": false}}
}
