package rulehub.medtech.iso_13485_document_control

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.iso_13485_document_control": true}, "qms": {"document_control_defined": true}}
}

test_denies_when_qms_document_control_defined_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_13485_document_control": true}, "qms": {"document_control_defined": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_13485_document_control": false}, "qms": {"document_control_defined": true}}
}

test_denies_when_control_disabled_and_document_control_missing if {
	count(deny) > 0 with input as {"controls": {"medtech.iso_13485_document_control": false}, "qms": {"document_control_defined": false}}
}
