package rulehub.betting.ads_bonus_terms_fair_clear

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.promotions.terms_fair_clear == false
	msg := "gambling.ads_bonus_terms_fair_clear: Bonus terms are fair, transparent; no misleading promotions"
}

deny contains msg if {
	input.controls["betting.ads_bonus_terms_fair_clear"] == false
	msg := "gambling.ads_bonus_terms_fair_clear: Generic control failed"
}
