package rulehub.fintech.pci_tls_min_version

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_tls_min_version": true}, "system": {"pci": {"pci_tls_min_version": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_tls_min_version_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_tls_min_version": true}, "system": {"pci": {"pci_tls_min_version": {"compliant": false}}}}
}
