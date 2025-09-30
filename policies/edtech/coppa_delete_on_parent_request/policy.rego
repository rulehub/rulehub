package rulehub.edtech.coppa_delete_on_parent_request

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violation triggers if a parent requested deletion but data not yet deleted
deny contains msg if {
	input.coppa.parent_requested_deletion
	input.coppa.deleted == false
	msg := "edtech.coppa_delete_on_parent_request: Delete child personal information upon verifiable parental request"
}

deny contains msg if {
	input.controls["edtech.coppa_delete_on_parent_request"] == false
	msg := "edtech.coppa_delete_on_parent_request: Generic control failed"
}
