package rulehub.fintech.aml_customer_risk_tiering

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.aml.customer_risk_score_assigned == false
	msg := "fintech.aml_customer_risk_tiering: Customer risk score not assigned"
}
