package rulehub.edtech.br_lgpd_children_consent_best_interest

# curated: include child.age < 13 trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.br_lgpd_children_consent_best_interest": true}, "child": {"age": 12}, "parental_consent": true}
}

test_denies_when_parental_consent_false if {
	count(deny) > 0 with input as {"controls": {"edtech.br_lgpd_children_consent_best_interest": true}, "child": {"age": 12}, "parental_consent": false}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.br_lgpd_children_consent_best_interest": false}, "child": {"age": 12}, "parental_consent": true}
}

test_denies_when_child_under_13_and_consent_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.br_lgpd_children_consent_best_interest": false}, "child": {"age": 12}, "parental_consent": false}
}
