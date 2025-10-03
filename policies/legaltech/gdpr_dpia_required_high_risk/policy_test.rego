package rulehub.legaltech.gdpr_dpia_required_high_risk

# curated: include high_risk_processing trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_dpia_required_high_risk": true}, "gdpr": {"high_risk_processing": true, "dpia_done": true}}
}

test_denies_when_gdpr_dpia_done_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_dpia_required_high_risk": true}, "gdpr": {"high_risk_processing": true, "dpia_done": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_dpia_required_high_risk": false}, "gdpr": {"high_risk_processing": true, "dpia_done": true}}
}

test_denies_when_control_disabled_and_dpia_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_dpia_required_high_risk": false}, "gdpr": {"high_risk_processing": true, "dpia_done": false}}
}

# Auto-generated granular test for controls["legaltech.gdpr_dpia_required_high_risk"]
test_denies_when_controls_legaltech_gdpr_dpia_required_high_risk_failing if {
	some _ in deny with input as {"controls": {}, "gdpr": {"high_risk_processing": true}, "controls[\"legaltech": {"gdpr_dpia_required_high_risk\"]": false}}
}
