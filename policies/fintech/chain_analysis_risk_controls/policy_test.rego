package rulehub.fintech.chain_analysis_risk_controls

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.chain_analysis_risk_controls": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.chain_analysis_risk_controls": false}}
}
