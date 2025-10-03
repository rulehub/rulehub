package rulehub.medtech.hipaa_baa_with_vendors

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.hipaa_baa_with_vendors": true}, "vendor": {"baa_signed": true}}
}

test_denies_when_vendor_baa_signed_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_baa_with_vendors": true}, "vendor": {"baa_signed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_baa_with_vendors": false}, "vendor": {"baa_signed": true}}
}

# Edge case: both BAA not signed and control disabled
test_denies_when_baa_not_signed_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_baa_with_vendors": false}, "vendor": {"baa_signed": false}}
}

# Auto-generated granular test for controls["medtech.hipaa_baa_with_vendors"]
test_denies_when_controls_medtech_hipaa_baa_with_vendors_failing if {
	some _ in deny with input as {"controls": {}, "vendor": {"baa_signed": true}, "controls[\"medtech": {"hipaa_baa_with_vendors\"]": false}}
}
