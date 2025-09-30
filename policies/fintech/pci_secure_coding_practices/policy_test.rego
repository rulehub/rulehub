package rulehub.fintech.pci_secure_coding_practices

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_secure_coding_practices": true}, "system": {"pci": {"pci_secure_coding_practices": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_secure_coding_practices_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_secure_coding_practices": true}, "system": {"pci": {"pci_secure_coding_practices": {"compliant": false}}}}
}
