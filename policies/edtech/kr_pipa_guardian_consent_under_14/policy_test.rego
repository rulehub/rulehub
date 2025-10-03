package rulehub.edtech.kr_pipa_guardian_consent_under_14

# curated: include child.age trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.kr_pipa_guardian_consent_under_14": true}, "child": {"age": 13}, "parental_consent": true}
}

test_denies_when_parental_consent_false if {
	count(deny) > 0 with input as {"controls": {"edtech.kr_pipa_guardian_consent_under_14": true}, "child": {"age": 13}, "parental_consent": false}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.kr_pipa_guardian_consent_under_14": false}, "child": {"age": 14}, "parental_consent": true}
}

test_denies_when_child_under_14_and_consent_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.kr_pipa_guardian_consent_under_14": false}, "child": {"age": 13}, "parental_consent": false}
}

# Auto-generated granular test for controls["edtech.kr_pipa_guardian_consent_under_14"]
test_denies_when_controls_edtech_kr_pipa_guardian_consent_under_14_failing if {
	some _ in deny with input as {"controls": {}, "child": {"age": true}, "controls[\"edtech": {"kr_pipa_guardian_consent_under_14\"]": false}}
}
