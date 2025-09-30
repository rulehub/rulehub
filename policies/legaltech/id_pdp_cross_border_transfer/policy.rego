package rulehub.legaltech.id_pdp_cross_border_transfer

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.transfer.outside_jurisdiction
	input.transfer.safeguards_in_place == false
	msg := "legaltech.id_pdp_cross_border_transfer: Adequacy/contractual safeguards for outbound transfers"
}

deny contains msg if {
	input.controls["legaltech.id_pdp_cross_border_transfer"] == false
	msg := "legaltech.id_pdp_cross_border_transfer: Generic control failed"
}
