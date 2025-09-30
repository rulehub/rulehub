package rulehub.medtech.health_data_cross_border_controls

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.transfer.outside_jurisdiction == true
	input.transfer.safeguards_in_place == false
	msg := "medtech.health_data_cross_border_controls: Cross-border transfer without safeguards (e.g., SCCs/BAAs/adequacy)"
}

deny contains msg if {
	input.controls["medtech.health_data_cross_border_controls"] == false
	msg := "medtech.health_data_cross_border_controls: Generic control failed"
}
