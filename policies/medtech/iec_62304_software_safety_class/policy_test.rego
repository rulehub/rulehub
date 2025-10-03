package rulehub.medtech.iec_62304_software_safety_class

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.iec_62304_software_safety_class": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62304_software_safety_class": false}}
}

test_denies_when_invalid_safety_class if {
	count(deny) > 0 with input as {
		"software": {"safety_class": "D"},
		"controls": {"medtech.iec_62304_software_safety_class": true},
	}
}

# Edge case: control disabled with invalid safety class should still deny via control flag
test_denies_when_control_disabled_and_invalid_safety_class if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62304_software_safety_class": false}, "software": {"safety_class": "D"}}
}

# Auto-generated granular test for controls["medtech.iec_62304_software_safety_class"]
test_denies_when_controls_medtech_iec_62304_software_safety_class_failing if {
	some _ in deny with input as {"controls": {}, "software": {"safety_class": true}, "controls[\"medtech": {"iec_62304_software_safety_class\"]": false}}
}
