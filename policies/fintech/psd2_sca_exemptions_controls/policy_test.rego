package rulehub.fintech.psd2_sca_exemptions_controls

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.psd2_sca_exemptions_controls": true}, "transaction": {"sca_passed": true}}
}

test_allows_when_sca_failed_but_control_enabled_conjunction_documentation if {
	allow with input as {"controls": {"fintech.psd2_sca_exemptions_controls": true}, "transaction": {"sca_passed": false}}
}

test_denies_when_control_disabled_and_sca_failed if {
	count(deny) > 0 with input as {"controls": {"fintech.psd2_sca_exemptions_controls": false}, "transaction": {"sca_passed": false}}
}
