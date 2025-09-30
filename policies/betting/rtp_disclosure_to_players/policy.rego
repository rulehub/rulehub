package rulehub.betting.rtp_disclosure_to_players

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.game.rtp_disclosed == false
	msg := "gambling.rtp_disclosure_to_players: Disclose RTP/house edge to players"
}

deny contains msg if {
	input.controls["betting.rtp_disclosure_to_players"] == false
	msg := "betting.rtp_disclosure_to_players: Generic control failed"
}
