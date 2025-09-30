package rulehub.legaltech.ccpa_notice_at_collection

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.ccpa.notice_at_collection_provided == false
	msg := "legaltech.ccpa_notice_at_collection: Provide notice at collection"
}

deny contains msg if {
	input.controls["legaltech.ccpa_notice_at_collection"] == false
	msg := "legaltech.ccpa_notice_at_collection: Generic control failed"
}
