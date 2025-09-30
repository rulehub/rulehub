package rulehub.edtech.coppa_parental_consent_under_13

# curated: include child.age trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.coppa_parental_consent_under_13": true}, "child": {"age": 12}, "coppa": {"verifiable_parental_consent": true}}
}

test_denies_when_coppa_verifiable_parental_consent_false if {
	count(deny) > 0 with input as {"controls": {"edtech.coppa_parental_consent_under_13": true}, "child": {"age": 12}, "coppa": {"verifiable_parental_consent": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.coppa_parental_consent_under_13": false}, "child": {"age": 12}, "coppa": {"verifiable_parental_consent": true}}
}

test_denies_when_parental_consent_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.coppa_parental_consent_under_13": false}, "child": {"age": 12}, "coppa": {"verifiable_parental_consent": false}}
}
