package rulehub.edtech.nz_notice_at_collection_edtech

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.notice.at_collection_provided == false
	msg := "edtech.nz_notice_at_collection_edtech: Provide privacy statement at collection (IPP 3)"
}

deny contains msg if {
	input.controls["edtech.nz_notice_at_collection_edtech"] == false
	msg := "edtech.nz_notice_at_collection_edtech: Generic control failed"
}
