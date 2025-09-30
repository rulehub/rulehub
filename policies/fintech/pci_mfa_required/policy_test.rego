package rulehub.fintech.pci_mfa_required

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_mfa_required": true}, "system": {"pci": {"pci_mfa_required": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_mfa_required_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_mfa_required": true}, "system": {"pci": {"pci_mfa_required": {"compliant": false}}}}
}
