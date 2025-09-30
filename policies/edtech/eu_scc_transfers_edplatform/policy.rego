package rulehub.edtech.eu_scc_transfers_edplatform

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.transfer.outside_eea
	input.transfer.scc_in_place == false
	msg := "edtech.eu_scc_transfers_edplatform: SCCs or equivalent safeguards for transfers to third countries"
}

deny contains msg if {
	input.controls["edtech.eu_scc_transfers_edplatform"] == false
	msg := "edtech.eu_scc_transfers_edplatform: Generic control failed"
}
