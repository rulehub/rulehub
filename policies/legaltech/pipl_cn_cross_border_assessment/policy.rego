package rulehub.legaltech.pipl_cn_cross_border_assessment

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.transfer.cn_outbound
	input.transfer.security_assessment_done == false
	msg := "legaltech.pipl_cn_cross_border_assessment: Security assessment for cross-border transfer"
}

deny contains msg if {
	input.controls["legaltech.pipl_cn_cross_border_assessment"] == false
	msg := "legaltech.pipl_cn_cross_border_assessment: Generic control failed"
}
