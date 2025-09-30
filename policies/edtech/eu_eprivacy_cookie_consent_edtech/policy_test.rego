package rulehub.edtech.eu_eprivacy_cookie_consent_edtech

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.eu_eprivacy_cookie_consent_edtech": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_eprivacy_cookie_consent_edtech": false}}
}

test_denies_when_non_essential_cookies_set_before_consent if {
	count(deny) > 0 with input as {
		"cookies": {"non_essential_set_before_consent": true},
		"controls": {"edtech.eu_eprivacy_cookie_consent_edtech": true},
	}
}

test_denies_when_non_essential_cookies_and_control_disabled if {
	count(deny) > 0 with input as {"cookies": {"non_essential_set_before_consent": true}, "controls": {"edtech.eu_eprivacy_cookie_consent_edtech": false}}
}
