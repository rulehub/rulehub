package rulehub.rg.au_audit_trails

test_allow_when_compliant if {
	allow with input as {"controls": {"rg.au_audit_trails": true}, "audit": {"trails_enabled": true}, "region": "AU"}
}

test_denies_when_audit_trails_enabled_false if {
	count(deny) > 0 with input as {"controls": {"rg.au_audit_trails": true}, "audit": {"trails_enabled": false}, "region": "AU"}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"rg.au_audit_trails": false}, "audit": {"trails_enabled": true}, "region": "AU"}
}

# Edge case: Both audit trails disabled and control disabled
test_denies_when_both_audit_disabled_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"rg.au_audit_trails": false}, "audit": {"trails_enabled": false}, "region": "AU"}
}
