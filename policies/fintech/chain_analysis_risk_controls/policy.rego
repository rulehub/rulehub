package rulehub.fintech.chain_analysis_risk_controls

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.chain_analysis_risk_controls"] == false
	msg := "fintech.chain_analysis_risk_controls: Generic fintech control failed"
}
