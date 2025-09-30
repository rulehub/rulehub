package rulehub.legaltech.vn_pdpd_notice_and_consent

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.notice.at_collection_provided == false
	msg := "legaltech.vn_pdpd_notice_and_consent: Provide notice obtain consent per PDPD"
}

deny contains msg if {
	input.consent.recorded == false
	msg := "legaltech.vn_pdpd_notice_and_consent: Provide notice obtain consent per PDPD"
}

deny contains msg if {
	input.controls["legaltech.vn_pdpd_notice_and_consent"] == false
	msg := "legaltech.vn_pdpd_notice_and_consent: Generic control failed"
}
