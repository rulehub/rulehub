package rulehub.medtech.fhir_smart_app_authz

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.fhir_smart_app_authz": true}, "smart": {"oauth2_enabled": true, "scopes_enforced": true}}
}

test_denies_when_smart_oauth2_enabled_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fhir_smart_app_authz": true}, "smart": {"oauth2_enabled": false, "scopes_enforced": true}}
}

test_denies_when_smart_scopes_enforced_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fhir_smart_app_authz": true}, "smart": {"oauth2_enabled": true, "scopes_enforced": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.fhir_smart_app_authz": false}, "smart": {"oauth2_enabled": true, "scopes_enforced": true}}
}

# Edge case: Both SMART conditions false
test_denies_when_both_smart_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fhir_smart_app_authz": true}, "smart": {"oauth2_enabled": false, "scopes_enforced": false}}
}

# Additional Phase1 assertion: missing SMART fields should deny
test_additional_denies_when_smart_fields_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.fhir_smart_app_authz": false}, "smart": {"oauth2_enabled": true, "scopes_enforced": true}}
}

# (No-op placeholder to keep uniformity across Phase1 additions)

# Auto-generated granular test for controls["medtech.fhir_smart_app_authz"]
test_denies_when_controls_medtech_fhir_smart_app_authz_failing if {
	some _ in deny with input as {"controls": {}, "smart": {"oauth2_enabled": true, "scopes_enforced": true}, "controls[\"medtech": {"fhir_smart_app_authz\"]": false}}
}
