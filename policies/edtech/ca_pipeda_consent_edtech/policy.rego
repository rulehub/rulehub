package rulehub.edtech.ca_pipeda_consent_edtech

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

## Deny when explicit evidence shows consent NOT obtained
deny contains msg if {
	input.pipeda.consent_obtained == false
	msg := "edtech.ca_pipeda_consent_edtech: Obtain meaningful consent; allow withdrawal; limit collection"
}

deny contains msg if {
	input.controls["edtech.ca_pipeda_consent_edtech"] == false
	msg := "edtech.ca_pipeda_consent_edtech: Generic control failed"
}
