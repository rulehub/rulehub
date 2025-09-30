package rulehub.medtech.iso_14971_risk_management_file

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.risk.file_exists == false
	msg := "medtech.iso_14971_risk_management_file: Risk management file not maintained"
}

deny contains msg if {
	input.risk.controls_traced == false
	msg := "medtech.iso_14971_risk_management_file: Risk control traceability not established"
}

deny contains msg if {
	input.controls["medtech.iso_14971_risk_management_file"] == false
	msg := "medtech.iso_14971_risk_management_file: Generic control failed"
}
