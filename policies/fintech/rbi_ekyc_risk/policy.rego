package rulehub.fintech.rbi_ekyc_risk

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.customer.country == "IN"
	input.ekyc.high_risk_controls_enabled == false
	msg := "RBI eKYC: high-risk eKYC controls must be enabled for Indian customers"
}
