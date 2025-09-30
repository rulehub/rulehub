package rulehub.medtech.uk_dtac_compliance

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.nhs.dptk_completed == false
	msg := "medtech.uk_dtac_compliance: Data Protection Toolkit (DPTK) not completed"
}

deny contains msg if {
	input.nhs.clinical_safety.dcb0129 == false
	msg := "medtech.uk_dtac_compliance: Clinical Safety DCB0129 compliance missing"
}

deny contains msg if {
	input.nhs.clinical_safety.dcb0160 == false
	msg := "medtech.uk_dtac_compliance: Clinical Safety DCB0160 compliance missing"
}

deny contains msg if {
	input.controls["medtech.uk_dtac_compliance"] == false
	msg := "medtech.uk_dtac_compliance: Generic control failed"
}
