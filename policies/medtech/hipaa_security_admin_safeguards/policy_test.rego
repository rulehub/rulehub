package rulehub.medtech.hipaa_security_admin_safeguards

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.hipaa_security_admin_safeguards": true}, "hipaa": {"security": {"risk_analysis_done": true, "sanctions_policy": true, "training_program": true}}}
}

test_denies_when_hipaa_security_risk_analysis_done_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_security_admin_safeguards": true}, "hipaa": {"security": {"risk_analysis_done": false, "sanctions_policy": true, "training_program": true}}}
}

test_denies_when_hipaa_security_sanctions_policy_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_security_admin_safeguards": true}, "hipaa": {"security": {"risk_analysis_done": true, "sanctions_policy": false, "training_program": true}}}
}

test_denies_when_hipaa_security_training_program_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_security_admin_safeguards": true}, "hipaa": {"security": {"risk_analysis_done": true, "sanctions_policy": true, "training_program": false}}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_security_admin_safeguards": false}, "hipaa": {"security": {"risk_analysis_done": true, "sanctions_policy": true, "training_program": true}}}
}

# Edge case: All security conditions false
test_denies_when_all_security_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_security_admin_safeguards": true}, "hipaa": {"security": {"risk_analysis_done": false, "sanctions_policy": false, "training_program": false}}}
}

# Auto-generated granular test for controls["medtech.hipaa_security_admin_safeguards"]
test_denies_when_controls_medtech_hipaa_security_admin_safeguards_failing if {
	some _ in deny with input as {"controls": {}, "hipaa": {"security": {"risk_analysis_done": true, "training_program": true, "sanctions_policy": true}}, "controls[\"medtech": {"hipaa_security_admin_safeguards\"]": false}}
}
