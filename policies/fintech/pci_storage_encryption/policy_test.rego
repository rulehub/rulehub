package rulehub.fintech.pci_storage_encryption

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_storage_encryption": true}, "system": {"pci": {"pci_storage_encryption": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_storage_encryption_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_storage_encryption": true}, "system": {"pci": {"pci_storage_encryption": {"compliant": false}}}}
}
