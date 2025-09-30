package rulehub.rg.self_exclusion_enforced

# curated

test_allow_when_compliant if {
	count(deny) == 0 with input as {"controls": {"rg.self_exclusion_enforced": true}, "customer": {"self_excluded": false}, "allow_bet": true}
}

test_denies_when_customer_self_excluded if {
	count(deny) > 0 with input as {"controls": {"rg.self_exclusion_enforced": true}, "customer": {"self_excluded": true}, "allow_bet": true}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"rg.self_exclusion_enforced": false}, "customer": {"self_excluded": true}, "allow_bet": true}
}
