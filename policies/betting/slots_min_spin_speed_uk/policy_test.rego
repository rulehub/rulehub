package rulehub.betting.slots_min_spin_speed_uk

# curated: use spin_time_ms matching policy (>=2500ms)
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.slots_min_spin_speed_uk": true}, "slots": {"spin_time_ms": 2600}}
}

test_denies_when_spin_speed_too_fast if {
	count(deny) > 0 with input as {"controls": {"betting.slots_min_spin_speed_uk": true}, "slots": {"spin_time_ms": 1200}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.slots_min_spin_speed_uk": false}, "slots": {"spin_time_ms": 2600}}
}

test_denies_when_spin_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.slots_min_spin_speed_uk": false}, "slots": {"spin_time_ms": 1200}}
}

# Auto-generated granular test for controls["betting.slots_min_spin_speed_uk"]
test_denies_when_controls_betting_slots_min_spin_speed_uk_failing if {
	some _ in deny with input as {"controls": {"betting.slots_min_spin_speed_uk": false}, "slots": {"spin_time_ms": 2000}}
}
