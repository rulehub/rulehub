package rulehub.betting.adr_provider_listed_uk

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.adr.provider_listed == false
	msg := "gambling.adr_provider_listed_uk: List approved ADR provider; handle disputes accordingly"
}

deny contains msg if {
	input.controls["betting.adr_provider_listed_uk"] == false
	msg := "gambling.adr_provider_listed_uk: Generic control failed"
}
