package rulehub.fintech.pci_account_lockout

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_account_lockout": true}, "system": {"pci": {"pci_account_lockout": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_account_lockout_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_account_lockout": true}, "system": {"pci": {"pci_account_lockout": {"compliant": false}}}}
}
