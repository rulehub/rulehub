package rulehub.betting.source_of_funds_thresholds

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.player.sof_collected == false
	msg := "betting.source_of_funds_thresholds: Source of funds not collected"
}

deny contains msg if {
	c := input.controls["betting.source_of_funds_thresholds"]
	c == false
	msg := "betting.source_of_funds_thresholds: Generic control failed"
}
