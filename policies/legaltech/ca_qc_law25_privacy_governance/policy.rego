package rulehub.legaltech.ca_qc_law25_privacy_governance

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.gov.privacy_officer_assigned == false
	msg := "legaltech.ca_qc_law25_privacy_governance: Assign privacy officer; implement governance policies (P-39.1 as amended)"
}

deny contains msg if {
	input.controls["legaltech.ca_qc_law25_privacy_governance"] == false
	msg := "legaltech.ca_qc_law25_privacy_governance: Generic control failed"
}
