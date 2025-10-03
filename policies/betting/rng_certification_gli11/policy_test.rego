package rulehub.betting.rng_certification_gli11

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.rng_certification_gli11": true}, "rng": {"certified": true}}
}

test_denies_when_rng_certified_false if {
	count(deny) > 0 with input as {"controls": {"betting.rng_certification_gli11": true}, "rng": {"certified": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.rng_certification_gli11": false}, "rng": {"certified": true}}
}

test_denies_when_rng_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.rng_certification_gli11": false}, "rng": {"certified": false}}
}

# Auto-generated granular test for controls["betting.rng_certification_gli11"]
test_denies_when_controls_betting_rng_certification_gli11_failing if {
	some _ in deny with input as {"controls": {}, "rng": {"certified": true}, "controls[\"betting": {"rng_certification_gli11\"]": false}}
}
