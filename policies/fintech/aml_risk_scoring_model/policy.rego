package rulehub.fintech.aml_risk_scoring_model

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.aml.customer_risk_score_assigned == false
	msg := "fintech.aml_risk_scoring_model: Customer risk score not assigned"
}
