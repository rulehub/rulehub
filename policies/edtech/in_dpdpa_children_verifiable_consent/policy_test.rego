package rulehub.edtech.in_dpdpa_children_verifiable_consent

# curated: include child.age trigger (<18) for denial scenario
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.in_dpdpa_children_verifiable_consent": true}, "child": {"age": 17}, "parental_consent": true}
}

test_denies_when_parental_consent_false if {
	count(deny) > 0 with input as {"controls": {"edtech.in_dpdpa_children_verifiable_consent": true}, "child": {"age": 17}, "parental_consent": false}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.in_dpdpa_children_verifiable_consent": false}, "child": {"age": 18}, "parental_consent": true}
}

test_denies_when_child_under_age_and_consent_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.in_dpdpa_children_verifiable_consent": false}, "child": {"age": 17}, "parental_consent": false}
}
