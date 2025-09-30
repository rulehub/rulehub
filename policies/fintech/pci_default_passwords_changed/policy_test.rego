package rulehub.fintech.pci_default_passwords_changed

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_default_passwords_changed": true}, "system": {"pci": {"pci_default_passwords_changed": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_default_passwords_changed_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_default_passwords_changed": true}, "system": {"pci": {"pci_default_passwords_changed": {"compliant": false}}}}
}
