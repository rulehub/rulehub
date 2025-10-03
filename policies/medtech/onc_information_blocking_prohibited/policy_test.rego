package rulehub.medtech.onc_information_blocking_prohibited

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.onc_information_blocking_prohibited": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"medtech.onc_information_blocking_prohibited": false}}
}

test_denies_when_information_blocking_detected if {
	count(deny) > 0 with input as {
		"onc": {"information_blocking_detected": true},
		"controls": {"medtech.onc_information_blocking_prohibited": true},
	}
}

# Edge case: control disabled while information blocking detected
test_denies_when_control_disabled_and_information_blocking_detected if {
	count(deny) > 0 with input as {"controls": {"medtech.onc_information_blocking_prohibited": false}, "onc": {"information_blocking_detected": true}}
}

# Auto-generated granular test for controls["medtech.onc_information_blocking_prohibited"]
test_denies_when_controls_medtech_onc_information_blocking_prohibited_failing if {
	some _ in deny with input as {"controls": {}, "onc": {"information_blocking_detected": true}, "controls[\"medtech": {"onc_information_blocking_prohibited\"]": false}}
}
