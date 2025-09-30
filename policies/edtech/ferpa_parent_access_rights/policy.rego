package rulehub.edtech.ferpa_parent_access_rights

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.ferpa.access_procedure_defined == false
	msg := "edtech.ferpa_parent_access_rights: Provide access to education records to parents/eligible students within reasonable time"
}

deny contains msg if {
	input.controls["edtech.ferpa_parent_access_rights"] == false
	msg := "edtech.ferpa_parent_access_rights: Generic control failed"
}
