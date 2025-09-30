package rulehub.fintech.rbi_ekyc_risk

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.rbi_ekyc_risk": true}, "ekyc": {"high_risk_controls_enabled": true}, "customer": {"country": "IN"}}
}

test_denies_when_ekyc_high_risk_controls_enabled_false if {
	count(deny) > 0 with input as {"controls": {"fintech.rbi_ekyc_risk": true}, "ekyc": {"high_risk_controls_enabled": false}, "customer": {"country": "IN"}}
}
