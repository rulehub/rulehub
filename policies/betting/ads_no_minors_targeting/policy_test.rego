package rulehub.betting.ads_no_minors_targeting

# curated: add ads.targeting_minors evidence
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.ads_no_minors_targeting": true}, "ads": {"targeting_minors": false}}
}

test_denies_when_ads_targeting_minors_true if {
	count(deny) > 0 with input as {"controls": {"betting.ads_no_minors_targeting": true}, "ads": {"targeting_minors": true}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.ads_no_minors_targeting": false}, "ads": {"targeting_minors": false}}
}

# Additional deny-focused test to exercise the second deny branch when ads target minors
test_denies_when_ads_explicitly_target_minors if {
	count(deny) > 0 with input as {"controls": {"betting.ads_no_minors_targeting": true}, "ads": {"targeting_minors": true}}
}

# Auto-generated granular test for controls.betting.ads_no_minors_targeting
test_denies_when_controls_betting_ads_no_minors_targeting_failing if {
	some _ in deny with input as {"controls": {"betting.ads_no_minors_targeting": false}, "ads": {"targeting_minors": false}}
}
