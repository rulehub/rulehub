package rulehub.legaltech.ae_pdpl_consent_notice

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.notice.at_collection_provided == false
	msg := "legaltech.ae_pdpl_consent_notice: Obtain consent provide transparent notice"
}

deny contains msg if {
	input.consent.recorded == false
	msg := "legaltech.ae_pdpl_consent_notice: Obtain consent provide transparent notice"
}

deny contains msg if {
	input.controls["legaltech.ae_pdpl_consent_notice"] == false
	msg := "legaltech.ae_pdpl_consent_notice: Generic control failed"
}
