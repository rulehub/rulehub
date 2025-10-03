package rulehub.legaltech.gdpr_cookie_consent_eprivacy

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_cookie_consent_eprivacy": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_cookie_consent_eprivacy": false}}
}

test_denies_when_non_essential_cookies_set_before_consent if {
	count(deny) > 0 with input as {
		"cookies": {"non_essential_set_before_consent": true},
		"controls": {"legaltech.gdpr_cookie_consent_eprivacy": true},
	}
}

test_denies_when_control_disabled_and_non_essential_set_before_consent if {
	count(deny) > 0 with input as {
		"controls": {"legaltech.gdpr_cookie_consent_eprivacy": false},
		"cookies": {"non_essential_set_before_consent": true},
	}
}

# Auto-generated granular test for controls["legaltech.gdpr_cookie_consent_eprivacy"]
test_denies_when_controls_legaltech_gdpr_cookie_consent_eprivacy_failing if {
	some _ in deny with input as {"controls": {}, "cookies": {"non_essential_set_before_consent": true}, "controls[\"legaltech": {"gdpr_cookie_consent_eprivacy\"]": false}}
}
