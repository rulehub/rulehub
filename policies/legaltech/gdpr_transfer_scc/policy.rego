package rulehub.legaltech.gdpr_transfer_scc

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.transfer.outside_eea
	input.transfer.scc_in_place == false
	msg := "legaltech.gdpr_transfer_scc: SCCs or equivalent safeguards for cross-border transfers"
}

deny contains msg if {
	input.controls["legaltech.gdpr_transfer_scc"] == false
	msg := "legaltech.gdpr_transfer_scc: Generic control failed"
}
