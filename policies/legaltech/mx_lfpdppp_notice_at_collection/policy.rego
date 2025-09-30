package rulehub.legaltech.mx_lfpdppp_notice_at_collection

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.notice.at_collection_provided == false
	msg := "legaltech.mx_lfpdppp_notice_at_collection: Provide privacy notice at/ before collection"
}

deny contains msg if {
	input.controls["legaltech.mx_lfpdppp_notice_at_collection"] == false
	msg := "legaltech.mx_lfpdppp_notice_at_collection: Generic control failed"
}
