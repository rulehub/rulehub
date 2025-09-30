package rulehub.legaltech.au_app_notice_at_collection

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.notice.at_collection_provided == false
	msg := "legaltech.au_app_notice_at_collection: Provide notice at/ before collection (APP 5)"
}

deny contains msg if {
	input.controls["legaltech.au_app_notice_at_collection"] == false
	msg := "legaltech.au_app_notice_at_collection: Generic control failed"
}
