package rulehub.edtech.eu_scc_transfers_edplatform

# curated: include outside_eea trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.eu_scc_transfers_edplatform": true}, "transfer": {"outside_eea": true, "scc_in_place": true}}
}

test_denies_when_transfer_scc_in_place_false if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_scc_transfers_edplatform": true}, "transfer": {"outside_eea": true, "scc_in_place": false}}
}

test_denies_when_transfer_outside_eea_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_scc_transfers_edplatform": false}, "transfer": {"outside_eea": true, "scc_in_place": true}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_scc_transfers_edplatform": false}, "transfer": {"outside_eea": false, "scc_in_place": true}}
}

# Auto-generated granular test for controls["edtech.eu_scc_transfers_edplatform"]
test_denies_when_controls_edtech_eu_scc_transfers_edplatform_failing if {
	some _ in deny with input as {"controls": {}, "transfer": {"outside_eea": true}, "controls[\"edtech": {"eu_scc_transfers_edplatform\"]": false}}
}
