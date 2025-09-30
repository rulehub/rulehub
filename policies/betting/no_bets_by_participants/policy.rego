package rulehub.betting.no_bets_by_participants

import future.keywords.in

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.participant_role in {"athlete", "coach", "referee"}
	input.bet.placed == true
	msg := "betting.no_bets_by_participants: Prohibited participant placed a bet"
}

deny contains msg if {
	c := input.controls["betting.no_bets_by_participants"]
	c == false
	msg := "betting.no_bets_by_participants: Generic control failed"
}
