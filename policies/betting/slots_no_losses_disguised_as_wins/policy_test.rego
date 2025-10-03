package rulehub.betting.slots_no_losses_disguised_as_wins

# curated: add evidence path slots.celebrate_losses_as_wins
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.slots_no_losses_disguised_as_wins": true}, "slots": {"celebrate_losses_as_wins": false}}
}

test_denies_when_slots_celebrate_losses_as_wins_true if {
	count(deny) > 0 with input as {"controls": {"betting.slots_no_losses_disguised_as_wins": true}, "slots": {"celebrate_losses_as_wins": true}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.slots_no_losses_disguised_as_wins": false}, "slots": {"celebrate_losses_as_wins": false}}
}

test_denies_when_celebrate_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.slots_no_losses_disguised_as_wins": false}, "slots": {"celebrate_losses_as_wins": true}}
}

# Auto-generated granular test for controls["betting.slots_no_losses_disguised_as_wins"]
test_denies_when_controls_betting_slots_no_losses_disguised_as_wins_failing if {
	some _ in deny with input as {"controls": {}, "slots": {"celebrate_losses_as_wins": true}, "controls[\"betting": {"slots_no_losses_disguised_as_wins\"]": false}}
}
