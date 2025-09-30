package rulehub.legaltech.gdpr_dpia_required_high_risk

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.gdpr.high_risk_processing
	input.gdpr.dpia_done == false
	msg := "legaltech.gdpr_dpia_required_high_risk: DPIA required completed for high-risk processing (Art. 35)"
}

deny contains msg if {
	input.controls["legaltech.gdpr_dpia_required_high_risk"] == false
	msg := "legaltech.gdpr_dpia_required_high_risk: Generic control failed"
}
