package rulehub.medtech.hipaa_security_tech_encryption

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.hipaa_security_tech_encryption": true}, "security": {"encryption_at_rest": true, "encryption_in_transit": true}}
}

test_denies_when_security_encryption_at_rest_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_security_tech_encryption": true}, "security": {"encryption_at_rest": false, "encryption_in_transit": true}}
}

test_denies_when_security_encryption_in_transit_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_security_tech_encryption": true}, "security": {"encryption_at_rest": true, "encryption_in_transit": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_security_tech_encryption": false}, "security": {"encryption_at_rest": true, "encryption_in_transit": true}}
}

# Edge case: Both security conditions false
test_denies_when_both_security_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_security_tech_encryption": true}, "security": {"encryption_at_rest": false, "encryption_in_transit": false}}
}
