package rulehub.betting.player_funds_segregation

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.funds.segregated == false
	msg := "gambling.player_funds_segregation: Segregate player funds from operational funds"
}

deny contains msg if {
	input.controls["betting.player_funds_segregation"] == false
	msg := "betting.player_funds_segregation: Generic control failed"
}
