package rulehub.medtech.onc_cures_api_fhir_r4

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.onc.api.fhir_r4_available == false
	msg := "medtech.onc_cures_api_fhir_r4: FHIR R4 API endpoints not available"
}

deny contains msg if {
	input.onc.api.uscdi_supported == false
	msg := "medtech.onc_cures_api_fhir_r4: USCDI data elements not supported via API"
}

deny contains msg if {
	input.controls["medtech.onc_cures_api_fhir_r4"] == false
	msg := "medtech.onc_cures_api_fhir_r4: Generic control failed"
}
