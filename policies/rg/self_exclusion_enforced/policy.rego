package rulehub.rg.self_exclusion_enforced

deny contains msg if {
	input.customer.self_excluded == true
	input.allow_bet == true
	msg := "Responsible Gambling: self-excluded player must not be allowed to place bets"
}
