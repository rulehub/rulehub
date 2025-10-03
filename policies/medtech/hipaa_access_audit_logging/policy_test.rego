package rulehub.medtech.hipaa_access_audit_logging

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.hipaa_access_audit_logging": true}, "audit": {"ephi_access_logged": true}}
}

test_denies_when_audit_ephi_access_logged_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_access_audit_logging": true}, "audit": {"ephi_access_logged": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_access_audit_logging": false}, "audit": {"ephi_access_logged": true}}
}

# Edge case: both ephi access not logged and control disabled
test_denies_when_both_ephi_not_logged_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_access_audit_logging": true}, "audit": {"ephi_access_logged": false}}
}

# Auto-generated granular test for controls["medtech.hipaa_access_audit_logging"]
test_denies_when_controls_medtech_hipaa_access_audit_logging_failing if {
	some _ in deny with input as {"controls": {}, "audit": {"ephi_access_logged": true}, "controls[\"medtech": {"hipaa_access_audit_logging\"]": false}}
}
