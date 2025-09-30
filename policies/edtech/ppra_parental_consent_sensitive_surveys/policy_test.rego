package rulehub.edtech.ppra_parental_consent_sensitive_surveys

# curated: include contains_sensitive_topics trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.ppra_parental_consent_sensitive_surveys": true}, "survey": {"contains_sensitive_topics": true, "parental_consent_obtained": true}}
}

test_denies_when_survey_parental_consent_obtained_false if {
	count(deny) > 0 with input as {"controls": {"edtech.ppra_parental_consent_sensitive_surveys": true}, "survey": {"contains_sensitive_topics": true, "parental_consent_obtained": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ppra_parental_consent_sensitive_surveys": false}, "survey": {"contains_sensitive_topics": false, "parental_consent_obtained": true}}
}

test_denies_when_sensitive_survey_and_consent_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.ppra_parental_consent_sensitive_surveys": false}, "survey": {"contains_sensitive_topics": true, "parental_consent_obtained": false}}
}
