package rulehub.legaltech.gdpr_transfer_scc

# curated: include outside_eea trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_transfer_scc": true}, "transfer": {"outside_eea": true, "scc_in_place": true}}
}

test_denies_when_transfer_scc_in_place_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_transfer_scc": true}, "transfer": {"outside_eea": true, "scc_in_place": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_transfer_scc": false}, "transfer": {"outside_eea": true, "scc_in_place": true}}
}

test_denies_when_control_disabled_and_scc_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_transfer_scc": false}, "transfer": {"outside_eea": true, "scc_in_place": false}}
}

# Auto-generated granular test for controls["legaltech.gdpr_transfer_scc"]
test_denies_when_controls_legaltech_gdpr_transfer_scc_failing if {
	some _ in deny with input as {"controls": {}, "transfer": {"outside_eea": true}, "controls[\"legaltech": {"gdpr_transfer_scc\"]": false}}
}
