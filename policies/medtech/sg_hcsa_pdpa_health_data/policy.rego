package rulehub.medtech.sg_hcsa_pdpa_health_data

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.pdpa.sg_purposes_specified == false
	msg := "medtech.sg_hcsa_pdpa_health_data: PDPA purposes for collection/use not specified"
}

deny contains msg if {
	input.sg.hcsa.licence_valid == false
	msg := "medtech.sg_hcsa_pdpa_health_data: HCSA licence not valid/current"
}

deny contains msg if {
	input.controls["medtech.sg_hcsa_pdpa_health_data"] == false
	msg := "medtech.sg_hcsa_pdpa_health_data: Generic control failed"
}
