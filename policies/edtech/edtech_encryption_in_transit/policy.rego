package rulehub.edtech.edtech_encryption_in_transit

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

## Deny only when explicit evidence says encryption_in_transit == false (absence is neutral)
deny contains msg if {
	input.security.encryption_in_transit == false
	msg := "edtech.edtech_encryption_in_transit: Encrypt student data in transit"
}

deny contains msg if {
	input.controls["edtech.edtech_encryption_in_transit"] == false
	msg := "edtech.edtech_encryption_in_transit: Generic control failed"
}
