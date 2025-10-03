package rulehub.edtech.ferpa_consent_or_exception_for_disclosure

# curated: include disclosure.requested trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.ferpa_consent_or_exception_for_disclosure": true}, "disclosure": {"requested": true, "exception_applies": true, "has_consent": true}}
}

test_allows_when_exception_absent_but_consent_present_conjunction_documentation if {
	# Disclosure may proceed because consent is present even though an exception does not apply.
	allow with input as {"controls": {"edtech.ferpa_consent_or_exception_for_disclosure": true}, "disclosure": {"requested": true, "exception_applies": false, "has_consent": true}}
}

test_allows_when_consent_absent_but_exception_present_conjunction_documentation if {
	# Disclosure may proceed because a valid exception applies even though explicit consent is absent.
	allow with input as {"controls": {"edtech.ferpa_consent_or_exception_for_disclosure": true}, "disclosure": {"requested": true, "exception_applies": true, "has_consent": false}}
}

test_denies_when_disclosure_no_consent_and_no_exception if {
	count(deny) > 0 with input as {"controls": {"edtech.ferpa_consent_or_exception_for_disclosure": true}, "disclosure": {"requested": true, "exception_applies": false, "has_consent": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ferpa_consent_or_exception_for_disclosure": false}, "disclosure": {"requested": false, "exception_applies": true, "has_consent": true}}
}

test_denies_when_disclosure_requested_and_no_consent_no_exception_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ferpa_consent_or_exception_for_disclosure": false}, "disclosure": {"requested": true, "exception_applies": false, "has_consent": false}}
}

# Auto-generated granular test for controls["edtech.ferpa_consent_or_exception_for_disclosure"]
test_denies_when_controls_edtech_ferpa_consent_or_exception_for_disclosure_failing if {
	some _ in deny with input as {"controls": {}, "disclosure": {"requested": true}, "controls[\"edtech": {"ferpa_consent_or_exception_for_disclosure\"]": false}}
}
