package rulehub.betting.slots_min_spin_speed_uk

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.slots.spin_time_ms < 2500
	msg := "gambling.slots_min_spin_speed_uk: Ensure minimum 2.5 seconds per spin"
}

deny contains msg if {
	input.controls["betting.slots_min_spin_speed_uk"] == false
	msg := "betting.slots_min_spin_speed_uk: Generic control failed"
}
