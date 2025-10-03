package rulehub.betting.adr_provider_listed_uk

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.adr_provider_listed_uk": true}, "adr": {"provider_listed": true}}
}

test_denies_when_adr_provider_listed_false if {
	count(deny) > 0 with input as {"controls": {"betting.adr_provider_listed_uk": true}, "adr": {"provider_listed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.adr_provider_listed_uk": false}, "adr": {"provider_listed": true}}
}

test_denies_when_adr_not_listed_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.adr_provider_listed_uk": false}, "adr": {"provider_listed": false}}
}

# Auto-generated granular test for controls.betting.adr_provider_listed_uk
test_denies_when_controls_betting_adr_provider_listed_uk_failing if {
	some _ in deny with input as {"controls": {"betting.adr_provider_listed_uk": false}, "adr": {"provider_listed": true}}
}
