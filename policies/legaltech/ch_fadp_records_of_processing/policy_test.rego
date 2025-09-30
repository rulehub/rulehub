package rulehub.legaltech.ch_fadp_records_of_processing

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.ch_fadp_records_of_processing": true}, "privacy": {"ropa_up_to_date": true}}
}

test_denies_when_privacy_ropa_up_to_date_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.ch_fadp_records_of_processing": true}, "privacy": {"ropa_up_to_date": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.ch_fadp_records_of_processing": false}, "privacy": {"ropa_up_to_date": true}}
}

# Edge case: control disabled and ROPA not up to date
test_denies_when_control_disabled_and_ropa_outdated if {
	count(deny) > 0 with input as {"controls": {"legaltech.ch_fadp_records_of_processing": true}, "privacy": {"ropa_up_to_date": false}}
}
