package rulehub.betting.ads_bonus_terms_fair_clear

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.ads_bonus_terms_fair_clear": true}, "promotions": {"terms_fair_clear": true}}
}

test_denies_when_promotions_terms_fair_clear_false if {
	count(deny) > 0 with input as {"controls": {"betting.ads_bonus_terms_fair_clear": true}, "promotions": {"terms_fair_clear": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.ads_bonus_terms_fair_clear": false}, "promotions": {"terms_fair_clear": true}}
}

test_denies_when_terms_unfair_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.ads_bonus_terms_fair_clear": false}, "promotions": {"terms_fair_clear": false}}
}

# Auto-generated granular test for controls.betting.ads_bonus_terms_fair_clear
test_denies_when_controls_betting_ads_bonus_terms_fair_clear_failing if {
	some _ in deny with input as {"controls": {"betting.ads_bonus_terms_fair_clear": false}, "promotions": {"terms_fair_clear": true}}
}
