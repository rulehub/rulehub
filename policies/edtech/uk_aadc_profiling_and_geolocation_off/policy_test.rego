package rulehub.edtech.uk_aadc_profiling_and_geolocation_off

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.uk_aadc_profiling_and_geolocation_off": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"edtech.uk_aadc_profiling_and_geolocation_off": false}}
}

test_denies_when_profiling_enabled_by_default if {
	count(deny) > 0 with input as {
		"aadc": {"profiling_enabled": true, "geolocation_enabled": false},
		"controls": {"edtech.uk_aadc_profiling_and_geolocation_off": true},
	}
}

test_denies_when_geolocation_enabled_by_default if {
	count(deny) > 0 with input as {
		"aadc": {"profiling_enabled": false, "geolocation_enabled": true},
		"controls": {"edtech.uk_aadc_profiling_and_geolocation_off": true},
	}
}

# Edge case: Both profiling and geolocation enabled
test_denies_when_both_profiling_and_geolocation_enabled if {
	count(deny) > 0 with input as {
		"aadc": {"profiling_enabled": true, "geolocation_enabled": true},
		"controls": {"edtech.uk_aadc_profiling_and_geolocation_off": true},
	}
}
