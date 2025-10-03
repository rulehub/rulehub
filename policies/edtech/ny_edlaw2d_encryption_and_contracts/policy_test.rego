package rulehub.edtech.ny_edlaw2d_encryption_and_contracts

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.ny_edlaw2d_encryption_and_contracts": true}, "security": {"encryption_at_rest": true, "encryption_in_transit": true}, "vendor": {"contract_compliant": true}}
}

test_denies_when_security_encryption_at_rest_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ny_edlaw2d_encryption_and_contracts": true}, "security": {"encryption_at_rest": false, "encryption_in_transit": true}, "vendor": {"contract_compliant": true}}
}

test_denies_when_security_encryption_in_transit_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ny_edlaw2d_encryption_and_contracts": true}, "security": {"encryption_at_rest": true, "encryption_in_transit": false}, "vendor": {"contract_compliant": true}}
}

test_denies_when_vendor_contract_compliant_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ny_edlaw2d_encryption_and_contracts": true}, "security": {"encryption_at_rest": true, "encryption_in_transit": true}, "vendor": {"contract_compliant": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ny_edlaw2d_encryption_and_contracts": false}, "security": {"encryption_at_rest": true, "encryption_in_transit": true}, "vendor": {"contract_compliant": true}}
}

# Edge case: All conditions false
test_denies_when_all_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ny_edlaw2d_encryption_and_contracts": true}, "security": {"encryption_at_rest": false, "encryption_in_transit": false}, "vendor": {"contract_compliant": false}}
}

# Auto-generated granular test for controls["edtech.ny_edlaw2d_encryption_and_contracts"]
test_denies_when_controls_edtech_ny_edlaw2d_encryption_and_contracts_failing if {
	some _ in deny with input as {"controls": {}, "security": {"encryption_at_rest": true, "encryption_in_transit": true}, "vendor": {"contract_compliant": true}, "controls[\"edtech": {"ny_edlaw2d_encryption_and_contracts\"]": false}}
}
