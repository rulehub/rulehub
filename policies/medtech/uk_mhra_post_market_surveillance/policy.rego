package rulehub.medtech.uk_mhra_post_market_surveillance

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.uk.pms_system_defined == false
	msg := "medtech.uk_mhra_post_market_surveillance: Post-market surveillance per UK requirements (GB)"
}

deny contains msg if {
	input.controls["medtech.uk_mhra_post_market_surveillance"] == false
	msg := "medtech.uk_mhra_post_market_surveillance: Generic control failed"
}
