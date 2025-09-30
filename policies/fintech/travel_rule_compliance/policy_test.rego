package rulehub.fintech.travel_rule_compliance

# curated: include crypto.transfer_active trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.travel_rule_compliance": true}, "crypto": {"transfer_active": true, "travel_rule_enforced": true}}
}

test_allows_when_not_enforced_but_control_enabled_conjunction_documentation if {
	allow with input as {"controls": {"fintech.travel_rule_compliance": true}, "crypto": {"transfer_active": true, "travel_rule_enforced": false}}
}

test_denies_when_control_disabled_and_not_enforced if {
	count(deny) > 0 with input as {"controls": {"fintech.travel_rule_compliance": false}, "crypto": {"transfer_active": true, "travel_rule_enforced": false}}
}
