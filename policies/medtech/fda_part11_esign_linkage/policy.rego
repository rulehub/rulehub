package rulehub.medtech.fda_part11_esign_linkage

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.part11.unique_ids == false
	msg := "medtech.fda_part11_esign_linkage: Electronic signatures not uniquely assigned to individuals"
}

deny contains msg if {
	input.part11.esign_linked_to_record == false
	msg := "medtech.fda_part11_esign_linkage: Electronic signature not cryptographically/bindingly linked to corresponding record"
}

deny contains msg if {
	input.controls["medtech.fda_part11_esign_linkage"] == false
	msg := "medtech.fda_part11_esign_linkage: Generic control failed"
}
