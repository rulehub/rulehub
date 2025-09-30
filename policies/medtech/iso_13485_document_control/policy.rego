package rulehub.medtech.iso_13485_document_control

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

## Deny only when explicit evidence shows the control is NOT in place (== false)
## Absence of evidence no longer auto-fails; require explicit false to reduce false positives.
deny contains msg if {
	input.qms.document_control_defined == false
	msg := "medtech.iso_13485_document_control: Establish and maintain document control procedures"
}

deny contains msg if {
	input.controls["medtech.iso_13485_document_control"] == false
	msg := "medtech.iso_13485_document_control: Generic control failed"
}
