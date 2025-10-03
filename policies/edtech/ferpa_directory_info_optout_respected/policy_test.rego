package rulehub.edtech.ferpa_directory_info_optout_respected

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.ferpa_directory_info_optout_respected": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ferpa_directory_info_optout_respected": false}}
}

test_denies_when_directory_info_released_after_optout if {
	count(deny) > 0 with input as {
		"student": {"directory_opt_out": true},
		"directory_info": {"disclosed": true},
		"controls": {"edtech.ferpa_directory_info_optout_respected": true},
	}
}

test_denies_when_directory_released_and_control_disabled if {
	count(deny) > 0 with input as {"student": {"directory_opt_out": true}, "directory_info": {"disclosed": true}, "controls": {"edtech.ferpa_directory_info_optout_respected": false}}
}

# Auto-generated granular test for controls["edtech.ferpa_directory_info_optout_respected"]
test_denies_when_controls_edtech_ferpa_directory_info_optout_respected_failing if {
	some _ in deny with input as {"controls": {}, "student": {"directory_opt_out": true}, "controls[\"edtech": {"ferpa_directory_info_optout_respected\"]": false}}
}
