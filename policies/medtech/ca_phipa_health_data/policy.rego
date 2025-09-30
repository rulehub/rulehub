package rulehub.medtech.ca_phipa_health_data

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.phipa.safeguards_implemented == false
	msg := "medtech.ca_phipa_health_data: Safeguards & consent principles for health information custodians"
}

deny contains msg if {
	input.controls["medtech.ca_phipa_health_data"] == false
	msg := "medtech.ca_phipa_health_data: Generic control failed"
}
