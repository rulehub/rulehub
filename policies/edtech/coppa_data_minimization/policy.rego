package rulehub.edtech.coppa_data_minimization

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.coppa.collected_fields > input.coppa.necessary_fields
	msg := "edtech.coppa_data_minimization: Limit collection to reasonably necessary for activity"
}

deny contains msg if {
	input.controls["edtech.coppa_data_minimization"] == false
	msg := "edtech.coppa_data_minimization: Generic control failed"
}
