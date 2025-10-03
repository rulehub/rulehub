package rulehub.edtech.edtech_encryption_at_rest

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.edtech_encryption_at_rest": true}, "security": {"encryption_at_rest": true}}
}

test_denies_when_security_encryption_at_rest_false if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_encryption_at_rest": true}, "security": {"encryption_at_rest": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_encryption_at_rest": false}, "security": {"encryption_at_rest": true}}
}

test_denies_when_encryption_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_encryption_at_rest": false}, "security": {"encryption_at_rest": false}}
}

# Auto-generated granular test for controls["edtech.edtech_encryption_at_rest"]
test_denies_when_controls_edtech_edtech_encryption_at_rest_failing if {
	some _ in deny with input as {"controls": {}, "security": {"encryption_at_rest": true}, "controls[\"edtech": {"edtech_encryption_at_rest\"]": false}}
}
