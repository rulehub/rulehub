package rulehub.edtech.ferpa_parent_access_rights

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.ferpa_parent_access_rights": true}, "ferpa": {"access_procedure_defined": true}}
}

test_denies_when_ferpa_access_procedure_defined_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ferpa_parent_access_rights": true}, "ferpa": {"access_procedure_defined": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ferpa_parent_access_rights": false}, "ferpa": {"access_procedure_defined": true}}
}

test_denies_when_access_procedure_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ferpa_parent_access_rights": false}, "ferpa": {"access_procedure_defined": false}}
}

# Auto-generated granular test for controls["edtech.ferpa_parent_access_rights"]
test_denies_when_controls_edtech_ferpa_parent_access_rights_failing if {
	some _ in deny with input as {"controls": {}, "ferpa": {"access_procedure_defined": true}, "controls[\"edtech": {"ferpa_parent_access_rights\"]": false}}
}
