package rulehub.legaltech.id_pdp_cross_border_transfer

# curated: include outside_jurisdiction trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.id_pdp_cross_border_transfer": true}, "transfer": {"outside_jurisdiction": true, "safeguards_in_place": true}}
}

test_denies_when_transfer_safeguards_in_place_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.id_pdp_cross_border_transfer": true}, "transfer": {"outside_jurisdiction": true, "safeguards_in_place": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.id_pdp_cross_border_transfer": false}, "transfer": {"outside_jurisdiction": true, "safeguards_in_place": true}}
}

test_denies_when_control_disabled_and_safeguards_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.id_pdp_cross_border_transfer": false}, "transfer": {"outside_jurisdiction": true, "safeguards_in_place": false}}
}
