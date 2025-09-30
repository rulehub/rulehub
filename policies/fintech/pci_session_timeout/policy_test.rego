package rulehub.fintech.pci_session_timeout

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_session_timeout": true}, "system": {"pci": {"pci_session_timeout": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_session_timeout_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_session_timeout": true}, "system": {"pci": {"pci_session_timeout": {"compliant": false}}}}
}
