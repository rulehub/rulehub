package rulehub.legaltech.legal_hold_no_delete_enforced

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.legal_hold_no_delete_enforced": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.legal_hold_no_delete_enforced": false}}
}

test_denies_when_deletion_during_active_legal_hold if {
	count(deny) > 0 with input as {
		"legal_hold": {"active": true},
		"deletion": {"performed": true},
		"controls": {"legaltech.legal_hold_no_delete_enforced": true},
	}
}

test_denies_when_control_disabled_and_deletion_during_active_legal_hold if {
	count(deny) > 0 with input as {"controls": {"legaltech.legal_hold_no_delete_enforced": false}, "legal_hold": {"active": true}, "deletion": {"performed": true}}
}
