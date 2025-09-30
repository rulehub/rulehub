package rulehub.legaltech.ca_qc_law25_privacy_governance

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.ca_qc_law25_privacy_governance": true}, "gov": {"privacy_officer_assigned": true}}
}

test_denies_when_gov_privacy_officer_assigned_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.ca_qc_law25_privacy_governance": true}, "gov": {"privacy_officer_assigned": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.ca_qc_law25_privacy_governance": false}, "gov": {"privacy_officer_assigned": true}}
}

# Edge case: control disabled and privacy officer not assigned
test_denies_when_control_disabled_and_privacy_officer_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.ca_qc_law25_privacy_governance": true}, "gov": {"privacy_officer_assigned": false}}
}
