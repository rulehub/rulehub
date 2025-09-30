package rulehub.medtech.fda_part11_system_validation

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

## Deny only when explicit evidence shows validation NOT available
deny contains msg if {
	input.part11.validation_evidence_available == false
	msg := "medtech.fda_part11_system_validation: Validate systems to ensure accuracy, reliability, consistent intended performance"
}

deny contains msg if {
	input.controls["medtech.fda_part11_system_validation"] == false
	msg := "medtech.fda_part11_system_validation: Generic control failed"
}
