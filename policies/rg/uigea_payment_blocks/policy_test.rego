package rulehub.rg.uigea_payment_blocks

# curated

test_allow_when_compliant if {
	count(deny) == 0 with input as {"controls": {"rg.uigea_payment_blocks": true}, "customer": {"country": "CA"}, "game_type": "unlawful_internet_gambling", "payment_method": "credit_card"}
}

test_denies_when_country_us if {
	count(deny) > 0 with input as {"controls": {"rg.uigea_payment_blocks": true}, "customer": {"country": "US"}, "game_type": "unlawful_internet_gambling", "payment_method": "credit_card"}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"rg.uigea_payment_blocks": false}, "customer": {"country": "US"}, "game_type": "unlawful_internet_gambling", "payment_method": "credit_card"}
}

test_denies_when_both_failure_conditions if {
	count(deny) > 0 with input as {"controls": {"rg.uigea_payment_blocks": false}, "customer": {"country": "US"}, "game_type": "unlawful_internet_gambling", "payment_method": "credit_card"}
}
