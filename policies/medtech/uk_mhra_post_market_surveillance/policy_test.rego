package rulehub.medtech.uk_mhra_post_market_surveillance

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.uk_mhra_post_market_surveillance": true}, "uk": {"pms_system_defined": true}}
}

test_denies_when_uk_pms_system_defined_false if {
	count(deny) > 0 with input as {"controls": {"medtech.uk_mhra_post_market_surveillance": true}, "uk": {"pms_system_defined": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.uk_mhra_post_market_surveillance": false}, "uk": {"pms_system_defined": true}}
}

# Edge case: control disabled and PMS system not defined
test_denies_when_control_disabled_and_pms_not_defined if {
	count(deny) > 0 with input as {"controls": {"medtech.uk_mhra_post_market_surveillance": true}, "uk": {"pms_system_defined": false}}
}

# Additional Phase1 test: missing PMS flag triggers deny
test_additional_denies_when_pms_flag_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.uk_mhra_post_market_surveillance": false}, "uk": {"pms_system_defined": true}}
}

# Auto-generated granular test for controls["medtech.uk_mhra_post_market_surveillance"]
test_denies_when_controls_medtech_uk_mhra_post_market_surveillance_failing if {
	some _ in deny with input as {"controls": {}, "uk": {"pms_system_defined": true}, "controls[\"medtech": {"uk_mhra_post_market_surveillance\"]": false}}
}
