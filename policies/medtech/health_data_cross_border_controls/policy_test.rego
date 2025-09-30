package rulehub.medtech.health_data_cross_border_controls

# curated: include outside_jurisdiction trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.health_data_cross_border_controls": true}, "transfer": {"outside_jurisdiction": true, "safeguards_in_place": true}}
}

test_denies_when_transfer_safeguards_in_place_false if {
	count(deny) > 0 with input as {"controls": {"medtech.health_data_cross_border_controls": true}, "transfer": {"outside_jurisdiction": true, "safeguards_in_place": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.health_data_cross_border_controls": false}, "transfer": {"outside_jurisdiction": false, "safeguards_in_place": true}}
}

# Edge case: control disabled while transfer is outside jurisdiction (should deny via control flag)
test_denies_when_control_disabled_and_transfer_outside_jurisdiction if {
	count(deny) > 0 with input as {"controls": {"medtech.health_data_cross_border_controls": false}, "transfer": {"outside_jurisdiction": true, "safeguards_in_place": true}}
}
