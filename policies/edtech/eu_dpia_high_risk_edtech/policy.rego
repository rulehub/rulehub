package rulehub.edtech.eu_dpia_high_risk_edtech

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.processing.high_risk
	input.privacy.dpia_done == false
	msg := "edtech.eu_dpia_high_risk_edtech: DPIA for systematic monitoring of students or profiling"
}

deny contains msg if {
	input.controls["edtech.eu_dpia_high_risk_edtech"] == false
	msg := "edtech.eu_dpia_high_risk_edtech: Generic control failed"
}
