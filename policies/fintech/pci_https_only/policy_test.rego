package rulehub.fintech.pci_https_only

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_https_only": true}, "system": {"pci": {"pci_https_only": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_https_only_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_https_only": true}, "system": {"pci": {"pci_https_only": {"compliant": false}}}}
}
