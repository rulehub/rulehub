package rulehub.legaltech.uk_gdpr_minor_consent

# curated: include user.age trigger (<13)
test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.uk_gdpr_minor_consent": true}, "user": {"age": 12}, "parental_consent": true}
}

test_denies_when_parental_consent_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.uk_gdpr_minor_consent": true}, "user": {"age": 12}, "parental_consent": false}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.uk_gdpr_minor_consent": false}, "user": {"age": 12}, "parental_consent": true}
}

test_denies_when_control_disabled_and_parental_consent_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.uk_gdpr_minor_consent": false}, "user": {"age": 12}, "parental_consent": false}
}
