package rulehub.aml.high_risk_country_edd

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["aml.high_risk_country_edd"] == false
	msg := "aml.high_risk_country_edd: enhanced due diligence not applied"
}
