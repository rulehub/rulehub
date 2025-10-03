package rulehub.legaltech.gdpr_consent_valid

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_consent_valid": true}, "consent": {"freely_given": true, "informed": true, "recorded": true, "unambiguous": true}}
}

test_denies_when_consent_freely_given_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_consent_valid": true}, "consent": {"freely_given": false, "informed": true, "recorded": true, "unambiguous": true}}
}

test_denies_when_consent_informed_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_consent_valid": true}, "consent": {"freely_given": true, "informed": false, "recorded": true, "unambiguous": true}}
}

test_denies_when_consent_recorded_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_consent_valid": true}, "consent": {"freely_given": true, "informed": true, "recorded": false, "unambiguous": true}}
}

test_denies_when_consent_unambiguous_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_consent_valid": true}, "consent": {"freely_given": true, "informed": true, "recorded": true, "unambiguous": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_consent_valid": false}, "consent": {"freely_given": true, "informed": true, "recorded": true, "unambiguous": true}}
}

# Edge case: Consent with null values (expect allow since policy only denies on explicit false)
test_allow_when_consent_null_values if {
	allow with input as {"controls": {"legaltech.gdpr_consent_valid": true}, "consent": {"freely_given": null, "informed": true, "recorded": true, "unambiguous": true}}
}

# Edge case: Multiple consent fields false
test_denies_when_multiple_consent_fields_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_consent_valid": true}, "consent": {"freely_given": false, "informed": false, "recorded": true, "unambiguous": true}}
}

# Auto-generated granular test for controls["legaltech.gdpr_consent_valid"]
test_denies_when_controls_legaltech_gdpr_consent_valid_failing if {
	some _ in deny with input as {"controls": {}, "consent": {"informed": true, "freely_given": true, "unambiguous": true, "recorded": true}, "controls[\"legaltech": {"gdpr_consent_valid\"]": false}}
}
