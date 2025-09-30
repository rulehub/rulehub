package rulehub.fintech.pci_log_retention

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_log_retention": true}, "system": {"pci": {"pci_log_retention": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_log_retention_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_log_retention": true}, "system": {"pci": {"pci_log_retention": {"compliant": false}}}}
}
