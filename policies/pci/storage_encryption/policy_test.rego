package rulehub.pci.storage_encryption

test_allow_when_compliant if {
	allow with input as {"controls": {"pci.storage_encryption": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"pci.storage_encryption": false}}
}
