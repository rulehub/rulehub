package rulehub.medtech.dicom_network_security_basic

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.dicom.tls_enabled == false
	msg := "medtech.dicom_network_security_basic: TLS not enabled for DICOM services"
}

deny contains msg if {
	input.dicom.ae_access_controls == false
	msg := "medtech.dicom_network_security_basic: AE title access controls missing"
}

deny contains msg if {
	input.controls["medtech.dicom_network_security_basic"] == false
	msg := "medtech.dicom_network_security_basic: Generic control failed"
}
