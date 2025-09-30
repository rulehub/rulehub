package rulehub.betting.slots_no_autoplay_uk

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.slots.autoplay_enabled == true
	msg := "gambling.slots_no_autoplay_uk: Disable autoplay functionality"
}

deny contains msg if {
	input.controls["betting.slots_no_autoplay_uk"] == false
	msg := "betting.slots_no_autoplay_uk: Generic control failed"
}
