package rulehub.medtech.device_data_integrity_hashing

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

## Deny only on explicit false evidence
deny contains msg if {
	input.device.data.integrity_protection_enabled == false
	msg := "medtech.device_data_integrity_hashing: Protect device log/data integrity via hashing/signatures"
}

deny contains msg if {
	input.controls["medtech.device_data_integrity_hashing"] == false
	msg := "medtech.device_data_integrity_hashing: Generic control failed"
}
