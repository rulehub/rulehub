package rulehub.medtech.fhir_smart_app_authz

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.smart.oauth2_enabled == false
	msg := "medtech.fhir_smart_app_authz: OAuth2 / OpenID Connect not enabled for SMART app authorization"
}

deny contains msg if {
	input.smart.scopes_enforced == false
	msg := "medtech.fhir_smart_app_authz: SMART/FHIR scopes not enforced for data access"
}

deny contains msg if {
	input.controls["medtech.fhir_smart_app_authz"] == false
	msg := "medtech.fhir_smart_app_authz: Generic control failed"
}
