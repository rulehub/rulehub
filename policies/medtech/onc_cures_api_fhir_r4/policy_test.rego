package rulehub.medtech.onc_cures_api_fhir_r4

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.onc_cures_api_fhir_r4": true}, "onc": {"api": {"fhir_r4_available": true, "uscdi_supported": true}}}
}

test_denies_when_onc_api_fhir_r4_available_false if {
	count(deny) > 0 with input as {"controls": {"medtech.onc_cures_api_fhir_r4": true}, "onc": {"api": {"fhir_r4_available": false, "uscdi_supported": true}}}
}

test_denies_when_onc_api_uscdi_supported_false if {
	count(deny) > 0 with input as {"controls": {"medtech.onc_cures_api_fhir_r4": true}, "onc": {"api": {"fhir_r4_available": true, "uscdi_supported": false}}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.onc_cures_api_fhir_r4": false}, "onc": {"api": {"fhir_r4_available": true, "uscdi_supported": true}}}
}

# Edge case: Both ONC API conditions false
test_denies_when_both_onc_api_false if {
	count(deny) > 0 with input as {"controls": {"medtech.onc_cures_api_fhir_r4": true}, "onc": {"api": {"fhir_r4_available": false, "uscdi_supported": false}}}
}

# Auto-generated granular test for controls["medtech.onc_cures_api_fhir_r4"]
test_denies_when_controls_medtech_onc_cures_api_fhir_r4_failing if {
	some _ in deny with input as {"controls": {}, "onc": {"api": {"fhir_r4_available": true, "uscdi_supported": true}}, "controls[\"medtech": {"onc_cures_api_fhir_r4\"]": false}}
}
