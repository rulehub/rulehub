package rulehub.legaltech.legal_hold_no_delete_enforced

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.legal_hold.active
	input.deletion.performed == true
	msg := "legaltech.legal_hold_no_delete_enforced: Block deletions during active legal hold"
}

deny contains msg if {
	input.controls["legaltech.legal_hold_no_delete_enforced"] == false
	msg := "legaltech.legal_hold_no_delete_enforced: Generic control failed"
}
