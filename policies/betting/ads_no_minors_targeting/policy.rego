package rulehub.betting.ads_no_minors_targeting

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.ads.targeting_minors == true
	msg := "gambling.ads_no_minors_targeting: Prevent targeting minors and appeal to children"
}

deny contains msg if {
	input.controls["betting.ads_no_minors_targeting"] == false
	msg := "gambling.ads_no_minors_targeting: Generic control failed"
}
