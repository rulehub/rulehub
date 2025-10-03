package rulehub.legaltech.ae_pdpl_consent_notice

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.ae_pdpl_consent_notice": true}, "consent": {"recorded": true}, "notice": {"at_collection_provided": true}}
}

test_denies_when_consent_recorded_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.ae_pdpl_consent_notice": true}, "consent": {"recorded": false}, "notice": {"at_collection_provided": true}}
}

test_denies_when_notice_at_collection_provided_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.ae_pdpl_consent_notice": true}, "consent": {"recorded": true}, "notice": {"at_collection_provided": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.ae_pdpl_consent_notice": false}, "consent": {"recorded": true}, "notice": {"at_collection_provided": true}}
}

# Edge case: consent absent; collection notice absent
test_denies_when_both_consent_notice_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.ae_pdpl_consent_notice": true}, "consent": {"recorded": false}, "notice": {"at_collection_provided": false}}
}

# Auto-generated granular test for controls["legaltech.ae_pdpl_consent_notice"]
test_denies_when_controls_legaltech_ae_pdpl_consent_notice_failing if {
	some _ in deny with input as {"controls": {}, "notice": {"at_collection_provided": true}, "consent": {"recorded": true}, "controls[\"legaltech": {"ae_pdpl_consent_notice\"]": false}}
}
