package rulehub.medtech.dicom_network_security_basic

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.dicom_network_security_basic": true}, "dicom": {"ae_access_controls": true, "tls_enabled": true}}
}

test_denies_when_dicom_ae_access_controls_false if {
	count(deny) > 0 with input as {"controls": {"medtech.dicom_network_security_basic": true}, "dicom": {"ae_access_controls": false, "tls_enabled": true}}
}

test_denies_when_dicom_tls_enabled_false if {
	count(deny) > 0 with input as {"controls": {"medtech.dicom_network_security_basic": true}, "dicom": {"ae_access_controls": true, "tls_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.dicom_network_security_basic": false}, "dicom": {"ae_access_controls": true, "tls_enabled": true}}
}

# Edge case: All DICOM conditions false
test_denies_when_all_dicom_false if {
	count(deny) > 0 with input as {"controls": {"medtech.dicom_network_security_basic": true}, "dicom": {"ae_access_controls": false, "tls_enabled": false}}
}
