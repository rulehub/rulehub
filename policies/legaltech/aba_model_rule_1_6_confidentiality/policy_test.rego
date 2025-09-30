package rulehub.legaltech.aba_model_rule_1_6_confidentiality

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.aba_model_rule_1_6_confidentiality": true}, "matter": {"safeguards_enabled": true}}
}

test_denies_when_matter_safeguards_enabled_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.aba_model_rule_1_6_confidentiality": true}, "matter": {"safeguards_enabled": false}}
}
