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
