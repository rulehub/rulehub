package rulehub.betting.official_data_only

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.official_data_only": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"betting.official_data_only": false}}
}

test_denies_when_non_official_data_used if {
	count(deny) > 0 with input as {
		"data": {"source": "scraped"},
		"controls": {"betting.official_data_only": true},
	}
}

test_denies_when_data_and_control_fail_extra if {
	count(deny) > 0 with input as {"data": {"source": "scraped"}, "controls": {"betting.official_data_only": false}}
}
