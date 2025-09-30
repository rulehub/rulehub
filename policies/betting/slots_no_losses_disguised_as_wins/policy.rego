package rulehub.betting.slots_no_losses_disguised_as_wins

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.slots.celebrate_losses_as_wins == true
	msg := "gambling.slots_no_losses_disguised_as_wins: No celebratory effects for returns less than/equal to stake"
}

deny contains msg if {
	input.controls["betting.slots_no_losses_disguised_as_wins"] == false
	msg := "betting.slots_no_losses_disguised_as_wins: Generic control failed"
}
