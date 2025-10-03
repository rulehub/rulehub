package rulehub.legaltech.tr_kvkk_verbis_registration

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.tr_kvkk_verbis_registration": true}, "kvkk": {"verbis_registered": true}}
}

test_denies_when_kvkk_verbis_registered_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.tr_kvkk_verbis_registration": true}, "kvkk": {"verbis_registered": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.tr_kvkk_verbis_registration": false}, "kvkk": {"verbis_registered": true}}
}

test_denies_when_control_disabled_and_verbis_not_registered if {
	count(deny) > 0 with input as {"controls": {"legaltech.tr_kvkk_verbis_registration": false}, "kvkk": {"verbis_registered": false}}
}

# Auto-generated granular test for controls["legaltech.tr_kvkk_verbis_registration"]
test_denies_when_controls_legaltech_tr_kvkk_verbis_registration_failing if {
	some _ in deny with input as {"controls": {}, "kvkk": {"verbis_registered": true}, "controls[\"legaltech": {"tr_kvkk_verbis_registration\"]": false}}
}
