package rulehub.edtech.edtech_encryption_in_transit

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.edtech_encryption_in_transit": true}, "security": {"encryption_in_transit": true}}
}

test_denies_when_security_encryption_in_transit_false if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_encryption_in_transit": true}, "security": {"encryption_in_transit": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_encryption_in_transit": false}, "security": {"encryption_in_transit": true}}
}

test_denies_when_encryption_in_transit_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_encryption_in_transit": false}, "security": {"encryption_in_transit": false}}
}

# Auto-generated granular test for controls["edtech.edtech_encryption_in_transit"]
test_denies_when_controls_edtech_edtech_encryption_in_transit_failing if {
	some _ in deny with input as {"controls": {}, "security": {"encryption_in_transit": true}, "controls[\"edtech": {"edtech_encryption_in_transit\"]": false}}
}
