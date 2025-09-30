package rulehub.edtech.eu_dpia_high_risk_edtech

# curated: include processing.high_risk flag
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.eu_dpia_high_risk_edtech": true}, "privacy": {"dpia_done": true}, "processing": {"high_risk": true}}
}

test_denies_when_high_risk_and_dpia_not_done if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_dpia_high_risk_edtech": true}, "privacy": {"dpia_done": false}, "processing": {"high_risk": true}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_dpia_high_risk_edtech": false}, "privacy": {"dpia_done": true}, "processing": {"high_risk": false}}
}

test_denies_when_high_risk_and_dpia_not_done_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.eu_dpia_high_risk_edtech": false}, "privacy": {"dpia_done": false}, "processing": {"high_risk": true}}
}
