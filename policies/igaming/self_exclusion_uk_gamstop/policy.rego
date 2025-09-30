package rulehub.igaming.self_exclusion_uk_gamstop

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.player.self_excluded == true
	input.session.blocked == false
	msg := "betting.self_exclusion_uk_gamstop: Self-excluded bettor not blocked"
}

deny contains msg if {
	c := input.controls["betting.self_exclusion_uk_gamstop"]
	c == false
	msg := "betting.self_exclusion_uk_gamstop: Generic control failed"
}
