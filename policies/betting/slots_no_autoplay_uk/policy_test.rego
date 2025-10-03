package rulehub.betting.slots_no_autoplay_uk

# curated: add slots.autoplay_enabled evidence
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.slots_no_autoplay_uk": true}, "slots": {"autoplay_enabled": false}}
}

test_denies_when_slots_autoplay_enabled_true if {
	count(deny) > 0 with input as {"controls": {"betting.slots_no_autoplay_uk": true}, "slots": {"autoplay_enabled": true}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.slots_no_autoplay_uk": false}, "slots": {"autoplay_enabled": false}}
}

test_denies_when_autoplay_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.slots_no_autoplay_uk": false}, "slots": {"autoplay_enabled": true}}
}

# Auto-generated granular test for controls["betting.slots_no_autoplay_uk"]
test_denies_when_controls_betting_slots_no_autoplay_uk_failing if {
	some _ in deny with input as {"controls": {}, "slots": {"autoplay_enabled": true}, "controls[\"betting": {"slots_no_autoplay_uk\"]": false}}
}
