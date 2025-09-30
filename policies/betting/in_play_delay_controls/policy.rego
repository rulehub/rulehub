package rulehub.betting.in_play_delay_controls

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.live_betting.enabled == true
	input.live_betting.delay_ms < input.policy.min_delay_ms
	msg := "betting.in_play_delay_controls: In-play bet delay below minimum"
}

deny contains msg if {
	c := input.controls["betting.in_play_delay_controls"]
	c == false
	msg := "betting.in_play_delay_controls: Generic control failed"
}
