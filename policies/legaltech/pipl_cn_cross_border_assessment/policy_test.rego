package rulehub.legaltech.pipl_cn_cross_border_assessment

# curated: include cn_outbound trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.pipl_cn_cross_border_assessment": true}, "transfer": {"cn_outbound": true, "security_assessment_done": true}}
}

test_denies_when_transfer_security_assessment_done_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.pipl_cn_cross_border_assessment": true}, "transfer": {"cn_outbound": true, "security_assessment_done": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.pipl_cn_cross_border_assessment": false}, "transfer": {"cn_outbound": true, "security_assessment_done": true}}
}

test_denies_when_control_disabled_and_security_assessment_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.pipl_cn_cross_border_assessment": false}, "transfer": {"cn_outbound": true, "security_assessment_done": false}}
}
