package rulehub.fintech.pci_key_management

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_key_management": true}, "system": {"pci": {"pci_key_management": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_key_management_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_key_management": true}, "system": {"pci": {"pci_key_management": {"compliant": false}}}}
}
