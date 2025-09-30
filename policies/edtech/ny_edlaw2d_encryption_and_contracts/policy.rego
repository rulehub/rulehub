package rulehub.edtech.ny_edlaw2d_encryption_and_contracts

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.security.encryption_at_rest == false
	msg := "edtech.ny_edlaw2d_encryption_and_contracts: Data not encrypted at rest"
}

deny contains msg if {
	input.security.encryption_in_transit == false
	msg := "edtech.ny_edlaw2d_encryption_and_contracts: Data not encrypted in transit"
}

deny contains msg if {
	input.vendor.contract_compliant == false
	msg := "edtech.ny_edlaw2d_encryption_and_contracts: Vendor contract missing required safeguards"
}

deny contains msg if {
	input.controls["edtech.ny_edlaw2d_encryption_and_contracts"] == false
	msg := "edtech.ny_edlaw2d_encryption_and_contracts: Generic control failed"
}
