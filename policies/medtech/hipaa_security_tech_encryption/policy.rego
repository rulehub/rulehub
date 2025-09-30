package rulehub.medtech.hipaa_security_tech_encryption

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.security.encryption_at_rest == false
	msg := "medtech.hipaa_security_tech_encryption: Encryption of ePHI at rest not implemented"
}

deny contains msg if {
	input.security.encryption_in_transit == false
	msg := "medtech.hipaa_security_tech_encryption: Encryption of ePHI in transit not implemented"
}

deny contains msg if {
	input.controls["medtech.hipaa_security_tech_encryption"] == false
	msg := "medtech.hipaa_security_tech_encryption: Generic control failed"
}
