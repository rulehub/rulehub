package rulehub.edtech.au_app_5_notice_edtech

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.notice.at_collection_provided == false
	msg := "edtech.au_app_5_notice_edtech: Provide APP 5 privacy notice"
}

deny contains msg if {
	input.controls["edtech.au_app_5_notice_edtech"] == false
	msg := "edtech.au_app_5_notice_edtech: Generic control failed"
}
