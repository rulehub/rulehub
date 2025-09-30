package rulehub.betting.rng_certification_gli11

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.rng.certified == false
	msg := "gambling.rng_certification_gli11: Games use RNG certified against GLI-11 or local equivalent"
}

deny contains msg if {
	input.controls["betting.rng_certification_gli11"] == false
	msg := "betting.rng_certification_gli11: Generic control failed"
}
