package rulehub.edtech.eu_gdpr_minors_consent_education

# curated: include child.age and min_consent_age policy context
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.eu_gdpr_minors_consent_education": true}, "child": {"age": 15}, "policy": {"eu": {"min_consent_age": 16}}, "parental_consent": true}
}

test_denies_when_parental_consent_false if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_gdpr_minors_consent_education": true}, "child": {"age": 15}, "policy": {"eu": {"min_consent_age": 16}}, "parental_consent": false}
}

test_denies_when_child_below_min_age_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_gdpr_minors_consent_education": false}, "child": {"age": 15}, "policy": {"eu": {"min_consent_age": 16}}, "parental_consent": true}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_gdpr_minors_consent_education": false}, "child": {"age": 17}, "policy": {"eu": {"min_consent_age": 16}}, "parental_consent": true}
}
