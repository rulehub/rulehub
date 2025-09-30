package rulehub.fintech.aml_customer_risk_tiering

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_customer_risk_tiering": true}, "aml": {"customer_risk_score_assigned": true}}
}

test_denies_when_aml_customer_risk_score_assigned_false if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_customer_risk_tiering": true}, "aml": {"customer_risk_score_assigned": false}}
}
