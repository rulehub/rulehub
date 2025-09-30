package rulehub.medtech.hipaa_baa_with_vendors

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

## Deny on explicit false evidence only
deny contains msg if {
	input.vendor.baa_signed == false
	msg := "medtech.hipaa_baa_with_vendors: Execute BAAs with vendors handling ePHI"
}

deny contains msg if {
	input.controls["medtech.hipaa_baa_with_vendors"] == false
	msg := "medtech.hipaa_baa_with_vendors: Generic control failed"
}
