package rulehub.betting.aml_high_risk_country_restrictions

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.customer.country in input.aml.high_risk_list
	input.aml.edd_applied == false
	msg := "gambling.aml_high_risk_country_restrictions: Apply EDD or restrict customers from high‑risk jurisdictions"
}

deny contains msg if {
	input.controls["betting.aml_high_risk_country_restrictions"] == false
	msg := "gambling.aml_high_risk_country_restrictions: Generic control failed"
}
