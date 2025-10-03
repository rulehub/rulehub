package rulehub.medtech.hipaa_mfa_privileged_access

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.hipaa_mfa_privileged_access": true}, "security": {"mfa_privileged_enabled": true}}
}

test_denies_when_security_mfa_privileged_enabled_false if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_mfa_privileged_access": true}, "security": {"mfa_privileged_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_mfa_privileged_access": false}, "security": {"mfa_privileged_enabled": true}}
}

# Edge case: both mfa for privileged disabled and control disabled
test_denies_when_both_mfa_disabled_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_mfa_privileged_access": true}, "security": {"mfa_privileged_enabled": false}}
}

# Extra Phase1 assertion: undefined MFA field should still cause deny
test_additional_denies_when_mfa_field_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.hipaa_mfa_privileged_access": false}, "security": {"mfa_privileged_enabled": true}}
}

# Auto-generated granular test for controls["medtech.hipaa_mfa_privileged_access"]
test_denies_when_controls_medtech_hipaa_mfa_privileged_access_failing if {
	some _ in deny with input as {"controls": {}, "security": {"mfa_privileged_enabled": true}, "controls[\"medtech": {"hipaa_mfa_privileged_access\"]": false}}
}
