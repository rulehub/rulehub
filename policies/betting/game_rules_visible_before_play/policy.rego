package rulehub.betting.game_rules_visible_before_play

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.game.rules_visible == false
	msg := "gambling.game_rules_visible_before_play: Display clear game rules before play"
}

deny contains msg if {
	input.controls["betting.game_rules_visible_before_play"] == false
	msg := "gambling.game_rules_visible_before_play: Generic control failed"
}
